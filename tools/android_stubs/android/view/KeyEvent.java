package android.view;
public class KeyEvent {
    public static int keyCodeFromString(String value) {
        try { return Integer.parseInt(value); } catch (NumberFormatException e) { return 0; }
    }
}
