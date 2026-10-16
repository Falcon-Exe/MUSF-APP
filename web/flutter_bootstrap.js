{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
        const appRunner = await engineInitializer.initializeEngine();

        window.addEventListener('flutter-first-frame', function () {
            const loader = document.getElementById('splash-screen');
            if (loader) {
                loader.remove();
            }
        }, { once: true });

        await appRunner.runApp();
    }
});
