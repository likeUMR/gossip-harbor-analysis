package android.view;

public class View {
    public static int getDefaultSize(int size, int measureSpec) {
        return (measureSpec & 0xC0000000) == 0 ? size : measureSpec & 0x3FFFFFFF;
    }
}
