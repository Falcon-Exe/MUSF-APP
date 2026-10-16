const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { getMessaging } = require("firebase-admin/messaging");
const crypto = require("crypto");

// Initialize Firebase Admin SDK
admin.initializeApp();

const r2AllowedFolders = new Set([
    "home/backgrounds",
    "home/slides",
    "students/profile_images",
    "executive/profile_images",
    "committees/images",
    "events/photos",
    "research/papers",
    "reports/pdf",
    "reels/videos",
    "prd/posters",
]);

exports.createR2UploadUrl = onRequest({ cors: true }, async (req, res) => {
    if (req.method === "OPTIONS") {
        res.set("Access-Control-Allow-Origin", "*");
        res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
        res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
        res.status(204).send("");
        return;
    }

    if (req.method !== "POST") {
        res.status(405).json({ error: "Method not allowed" });
        return;
    }

    try {
        if (process.env.R2_REQUIRE_AUTH !== "false") {
            await verifySupabaseUser(req);
        }

        const config = getR2Config();
        const body = req.body || {};
        const contentType = sanitizeContentType(body.contentType);
        const folder = sanitizeFolder(body.folder);
        const fileName = sanitizeFileName(body.fileName);
        const sizeBytes = Number(body.sizeBytes || 0);
        const maxUploadBytes = Number(process.env.R2_MAX_UPLOAD_BYTES || 250 * 1024 * 1024);

        if (!r2AllowedFolders.has(folder)) {
            res.status(400).json({ error: "Unsupported R2 upload folder" });
            return;
        }

        if (!fileName) {
            res.status(400).json({ error: "fileName is required" });
            return;
        }

        if (!contentType) {
            res.status(400).json({ error: "contentType is required" });
            return;
        }

        if (!Number.isFinite(sizeBytes) || sizeBytes <= 0 || sizeBytes > maxUploadBytes) {
            res.status(400).json({ error: "Invalid upload size" });
            return;
        }

        const key = [
            folder,
            new Date().toISOString().slice(0, 10),
            crypto.randomUUID(),
            fileName,
        ].join("/");
        const uploadUrl = createR2PresignedPutUrl({ ...config, key });
        const fileUrl = `${config.publicBaseUrl}/${encodeKeyPath(key)}`;

        res.status(200).json({
            uploadUrl,
            fileUrl,
            key,
            contentType,
            expiresInSeconds: config.expiresInSeconds,
        });
    } catch (error) {
        console.error("R2 signer error:", error);
        res.status(error.statusCode || 500).json({
            error: error.message || "Could not sign R2 upload",
        });
    }
});

exports.deleteR2File = onRequest({ cors: true }, async (req, res) => {
    if (req.method === "OPTIONS") {
        res.set("Access-Control-Allow-Origin", "*");
        res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
        res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
        res.status(204).send("");
        return;
    }

    if (req.method !== "POST") {
        res.status(405).json({ error: "Method not allowed" });
        return;
    }

    try {
        if (process.env.R2_REQUIRE_AUTH !== "false") {
            await verifySupabaseUser(req);
        }

        const config = getR2Config();
        const key = sanitizeKey(req.body?.key || keyFromPublicUrl(req.body?.fileUrl, config.publicBaseUrl));

        if (!key) {
            res.status(400).json({ error: "key or fileUrl is required" });
            return;
        }

        const folder = key.split("/").slice(0, 2).join("/");
        if (!r2AllowedFolders.has(folder)) {
            res.status(400).json({ error: "Unsupported R2 delete folder" });
            return;
        }

        await deleteR2Object({ ...config, key });
        res.status(200).json({ ok: true });
    } catch (error) {
        console.error("R2 delete error:", error);
        res.status(error.statusCode || 500).json({
            error: error.message || "Could not delete R2 file",
        });
    }
});

async function verifySupabaseUser(req) {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
    const authorization = req.get("Authorization") || "";

    if (!supabaseUrl || !supabaseAnonKey) {
        throw new HttpError(
            500,
            "Missing Supabase auth configuration for R2 signer.",
        );
    }

    if (!authorization.startsWith("Bearer ")) {
        throw new HttpError(401, "Missing Supabase bearer token.");
    }

    const response = await fetch(`${supabaseUrl.replace(/\/+$/, "")}/auth/v1/user`, {
        headers: {
            Authorization: authorization,
            apikey: supabaseAnonKey,
        },
    });

    if (!response.ok) {
        throw new HttpError(401, "Invalid Supabase session.");
    }
}

class HttpError extends Error {
    constructor(statusCode, message) {
        super(message);
        this.statusCode = statusCode;
    }
}

function getR2Config() {
    const accountId = process.env.R2_ACCOUNT_ID;
    const bucket = process.env.R2_BUCKET;
    const accessKeyId = process.env.R2_ACCESS_KEY_ID;
    const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;
    const publicBaseUrl = (process.env.R2_PUBLIC_BASE_URL || "").replace(/\/+$/, "");
    const expiresInSeconds = Number(process.env.R2_UPLOAD_URL_TTL_SECONDS || 900);

    if (!accountId || !bucket || !accessKeyId || !secretAccessKey || !publicBaseUrl) {
        throw new Error(
            "Missing R2 configuration. Set R2_ACCOUNT_ID, R2_BUCKET, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, and R2_PUBLIC_BASE_URL.",
        );
    }

    return {
        accountId,
        bucket,
        accessKeyId,
        secretAccessKey,
        publicBaseUrl,
        expiresInSeconds,
    };
}

function createR2PresignedPutUrl({
    accountId,
    bucket,
    accessKeyId,
    secretAccessKey,
    key,
    expiresInSeconds,
}) {
    const host = `${accountId}.r2.cloudflarestorage.com`;
    const now = new Date();
    const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, "");
    const dateStamp = amzDate.slice(0, 8);
    const region = "auto";
    const service = "s3";
    const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
    const canonicalUri = `/${bucket}/${encodeKeyPath(key)}`;
    const queryParams = {
        "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
        "X-Amz-Credential": `${accessKeyId}/${credentialScope}`,
        "X-Amz-Date": amzDate,
        "X-Amz-Expires": String(expiresInSeconds),
        "X-Amz-SignedHeaders": "host",
    };
    const canonicalQueryString = canonicalQuery(queryParams);
    const canonicalHeaders = `host:${host}\n`;
    const signedHeaders = "host";
    const payloadHash = "UNSIGNED-PAYLOAD";
    const canonicalRequest = [
        "PUT",
        canonicalUri,
        canonicalQueryString,
        canonicalHeaders,
        signedHeaders,
        payloadHash,
    ].join("\n");
    const stringToSign = [
        "AWS4-HMAC-SHA256",
        amzDate,
        credentialScope,
        sha256Hex(canonicalRequest),
    ].join("\n");
    const signature = hmacHex(getSignatureKey(secretAccessKey, dateStamp, region, service), stringToSign);

    return `https://${host}${canonicalUri}?${canonicalQueryString}&X-Amz-Signature=${signature}`;
}

async function deleteR2Object({
    accountId,
    bucket,
    accessKeyId,
    secretAccessKey,
    key,
}) {
    const host = `${accountId}.r2.cloudflarestorage.com`;
    const now = new Date();
    const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, "");
    const dateStamp = amzDate.slice(0, 8);
    const region = "auto";
    const service = "s3";
    const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
    const canonicalUri = `/${bucket}/${encodeKeyPath(key)}`;
    const canonicalHeaders = `host:${host}\nx-amz-content-sha256:UNSIGNED-PAYLOAD\nx-amz-date:${amzDate}\n`;
    const signedHeaders = "host;x-amz-content-sha256;x-amz-date";
    const canonicalRequest = [
        "DELETE",
        canonicalUri,
        "",
        canonicalHeaders,
        signedHeaders,
        "UNSIGNED-PAYLOAD",
    ].join("\n");
    const stringToSign = [
        "AWS4-HMAC-SHA256",
        amzDate,
        credentialScope,
        sha256Hex(canonicalRequest),
    ].join("\n");
    const signature = hmacHex(getSignatureKey(secretAccessKey, dateStamp, region, service), stringToSign);

    const response = await fetch(`https://${host}${canonicalUri}`, {
        method: "DELETE",
        headers: {
            Authorization: `AWS4-HMAC-SHA256 Credential=${accessKeyId}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`,
            "x-amz-content-sha256": "UNSIGNED-PAYLOAD",
            "x-amz-date": amzDate,
        },
    });

    if (!response.ok && response.status !== 404) {
        throw new Error(`R2 delete failed (${response.status}): ${await response.text()}`);
    }
}

function canonicalQuery(params) {
    return Object.keys(params)
        .sort()
        .map((key) => `${awsEncode(key)}=${awsEncode(params[key])}`)
        .join("&");
}

function getSignatureKey(secretAccessKey, dateStamp, region, service) {
    const kDate = hmacBuffer(`AWS4${secretAccessKey}`, dateStamp);
    const kRegion = hmacBuffer(kDate, region);
    const kService = hmacBuffer(kRegion, service);
    return hmacBuffer(kService, "aws4_request");
}

function hmacBuffer(key, value) {
    return crypto.createHmac("sha256", key).update(value).digest();
}

function hmacHex(key, value) {
    return crypto.createHmac("sha256", key).update(value).digest("hex");
}

function sha256Hex(value) {
    return crypto.createHash("sha256").update(value).digest("hex");
}

function encodeKeyPath(key) {
    return key.split("/").map(awsEncode).join("/");
}

function awsEncode(value) {
    return encodeURIComponent(value).replace(/[!'()*]/g, (char) =>
        `%${char.charCodeAt(0).toString(16).toUpperCase()}`,
    );
}

function sanitizeFolder(value) {
    return String(value || "")
        .trim()
        .replace(/\\/g, "/")
        .split("/")
        .filter(Boolean)
        .map((part) => part.replace(/[^A-Za-z0-9_-]/g, "-"))
        .join("/");
}

function sanitizeKey(value) {
    return String(value || "")
        .trim()
        .replace(/\\/g, "/")
        .split("/")
        .filter(Boolean)
        .map((part) => part.replace(/[^A-Za-z0-9._-]/g, "_"))
        .join("/");
}

function keyFromPublicUrl(fileUrl, publicBaseUrl) {
    const url = String(fileUrl || "").trim();
    if (!url || !publicBaseUrl || !url.startsWith(`${publicBaseUrl}/`)) {
        return "";
    }
    return decodeURIComponent(url.slice(publicBaseUrl.length + 1));
}

function sanitizeFileName(value) {
    return String(value || "")
        .trim()
        .replace(/[^A-Za-z0-9._-]/g, "_")
        .slice(0, 160);
}

function sanitizeContentType(value) {
    return String(value || "")
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9.+/-]/g, "");
}

/**
 * Triggered when a new document is added to the "notifications" collection.
 * 
 * Expected custom document format:
 * {
 *   studentID: "12345",
 *   title: "Notification Title",
 *   message: "Notification Body",
 *   createdAt: Timestamp
 * }
 */
exports.sendPushNotification = onDocumentCreated("notifications/{docId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        console.log("No data associated with the event");
        return;
    }

    const data = snapshot.data();
    const studentID = data.studentID;
    const title = data.title || "New Message";
    const messageBody = data.message || "You have a new notification.";

    if (!studentID) {
        console.log("No studentID provided in the notification document.");
        return null;
    }

    try {
        // 1. Look up the student's FCM token from the students collection
        const studentSnapshot = await admin.firestore()
            .collection("students")
            .where("studentID", "==", studentID)
            .limit(1)
            .get();

        if (studentSnapshot.empty) {
            console.log(`Student with ID ${studentID} not found.`);
            return null;
        }

        const studentDoc = studentSnapshot.docs[0];
        const studentData = studentDoc.data();
        const token = studentData.fcmToken;

        if (!token) {
            console.log(`Student ${studentID} does not have an fcmToken registered.`);
            return null;
        }

        // 2. Construct the push notification payload
        const payload = {
            token: token,
            notification: {
                title: title,
                body: messageBody,
            },
            android: {
                priority: "high",
                notification: {
                    sound: "default",
                    channelId: "union_events" // Must match the channel created in your Android app if applicable
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default"
                    }
                }
            }
        };

        // 3. Send the notification via Firebase Cloud Messaging
        const response = await getMessaging().send(payload);
        console.log(`Successfully sent message to ${studentID}:`, response);

        // (Optional) Update the notification document to mark it as sent
        await snapshot.ref.update({
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            sentSuccess: true
        });

        return null;

    } catch (error) {
        console.error("Error sending push notification:", error);

        // Mark as failed in Firestore
        await snapshot.ref.update({
            sentSuccess: false,
            error: error.message
        });

        return null;
    }
});
