import java.net.URL;
import java.net.URLClassLoader;
import java.nio.file.Path;

public class CaptureProtected {
    public static void main(String[] args) throws Exception {
        URL[] urls = {
            Path.of(args[0]).toUri().toURL(),
            Path.of(args[1]).toUri().toURL(),
            Path.of("analysis_data/logic_index/android/protected-loaders-instrumented.jar").toUri().toURL()
        };
        try (URLClassLoader loader = new URLClassLoader(urls)) {
            Class.forName(args.length > 2 ? args[2] : "com.appsflyer.internal.AFa1hSDK", true, loader);
        }
    }
}
