import java.util.zip.*;
import java.nio.file.*;
import org.objectweb.asm.*;

public class InstrumentReflection {
    public static void main(String[] args) throws Exception {
        try (ZipInputStream input = new ZipInputStream(Files.newInputStream(Path.of(args[0])));
             ZipOutputStream output = new ZipOutputStream(Files.newOutputStream(Path.of(args[1])))) {
            ZipEntry entry;
            while ((entry = input.getNextEntry()) != null) {
                byte[] data = input.readAllBytes();
                if (entry.getName().startsWith("com/appsflyer/internal/") && entry.getName().endsWith(".class")) {
                    ClassReader reader = new ClassReader(data);
                    ClassWriter writer = new ClassWriter(0);
                    reader.accept(new ClassVisitor(Opcodes.ASM9, writer) {
                        @Override public MethodVisitor visitMethod(int access, String name, String descriptor, String signature, String[] exceptions) {
                            return new MethodVisitor(Opcodes.ASM9, super.visitMethod(access, name, descriptor, signature, exceptions)) {
                                @Override public void visitMethodInsn(int op, String owner, String method, String desc, boolean itf) {
                                    if (owner.equals("java/lang/reflect/Method") && method.equals("invoke")) {
                                        super.visitMethodInsn(Opcodes.INVOKESTATIC, "CaptureBridge", "invoke", "(Ljava/lang/reflect/Method;Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;", false);
                                    } else if (owner.equals("java/lang/reflect/Constructor") && method.equals("newInstance")) {
                                        super.visitMethodInsn(Opcodes.INVOKESTATIC, "CaptureBridge", "construct", "(Ljava/lang/reflect/Constructor;[Ljava/lang/Object;)Ljava/lang/Object;", false);
                                    } else super.visitMethodInsn(op, owner, method, desc, itf);
                                }
                            };
                        }
                    }, 0);
                    data = writer.toByteArray();
                }
                output.putNextEntry(new ZipEntry(entry.getName()));
                output.write(data);
                output.closeEntry();
            }
        }
    }
}
