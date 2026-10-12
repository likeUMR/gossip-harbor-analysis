package dalvik.system;

public class DexFile {
    public static DexFile loadDex(String source, String output, int flags) { return new DexFile(); }
    public Class<?> loadClass(String name, ClassLoader loader) throws ClassNotFoundException {
        return Class.forName(name, true, loader);
    }
    public void close() {}
}
