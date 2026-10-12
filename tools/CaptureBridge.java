import java.lang.reflect.Method;
import java.lang.reflect.Constructor;

public class CaptureBridge {
    public static Object invoke(Method method, Object receiver, Object[] args) throws Exception {
        String owner = method.getDeclaringClass().getName();
        if (owner.equals("dalvik.system.DexFile") && method.getName().equals("loadDex")) {
            java.nio.file.Path source = java.nio.file.Path.of((String) args[0]);
            byte[] data = java.nio.file.Files.readAllBytes(source);
            String hash = java.util.HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(data));
            java.nio.file.Path directory = java.nio.file.Path.of(System.getProperty("gh.capture.dir"));
            java.nio.file.Files.createDirectories(directory);
            java.nio.file.Files.write(directory.resolve(hash + ".dex"), data);
            System.out.println("CAPTURED_DEX " + hash + " " + data.length);
            if (data.length == 7258 || data.length == 6578) return new dalvik.system.DexFile();
            throw new UnsupportedOperationException("Captured protected DEX before loading its code");
        }
        if (owner.equals("dalvik.system.DexFile") && method.getName().equals("loadClass"))
            return Class.forName(((String) args[0]).replace('/', '.'), true, (ClassLoader) args[1]);
        if (owner.startsWith("android.")) {
            System.out.println("ANDROID " + method + " " + java.util.Arrays.toString(args));
            Class<?> type = method.getReturnType();
            if (owner.equals("android.graphics.Color")) {
                int color = (Integer) args[0];
                if (method.getName().equals("blue")) return color & 255;
                if (method.getName().equals("red")) return color >> 16 & 255;
                if (method.getName().equals("green")) return color >> 8 & 255;
                if (method.getName().equals("alpha")) return color >>> 24;
            }
            if (method.getName().equals("resolveOpacity")) {
                int a = (Integer) args[0], b = (Integer) args[1];
                return a == b ? a : a == 0 || b == 0 ? 0 : a == -3 || b == -3 ? -3 : a == -2 || b == -2 ? -2 : -1;
            }
            if (type == int.class) return 0;
            if (type == long.class) return 0L;
            if (type == float.class) return 0F;
            if (type == double.class) return 0D;
            if (type == boolean.class) return false;
            if (type == void.class) return null;
            throw new UnsupportedOperationException("Android return needs implementation: " + method);
        }
        System.out.println("REFLECT " + method + " " + java.util.Arrays.toString(args));
        method.setAccessible(true);
        return method.invoke(receiver, args);
    }
    public static Object construct(Constructor<?> constructor, Object[] args) throws Exception {
        System.out.println("CONSTRUCT " + constructor + " " + java.util.Arrays.toString(args));
        if (constructor.getDeclaringClass().getName().matches(".*AFk1[rt]SDK"))
            System.out.println("CIPHER_PARAMETERS " + java.util.Arrays.deepToString(args));
        if (constructor.getDeclaringClass() == java.io.ByteArrayInputStream.class && args.length == 3) {
            byte[] bytes = java.util.Arrays.copyOfRange((byte[]) args[0], (Integer) args[1], (Integer) args[1] + (Integer) args[2]);
            String hash = java.util.HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(bytes));
            java.nio.file.Path directory = java.nio.file.Path.of(System.getProperty("gh.capture.dir"));
            java.nio.file.Files.createDirectories(directory);
            java.nio.file.Files.write(directory.resolve(hash + ".cipher"), bytes);
        }
        return constructor.newInstance(args);
    }
}
