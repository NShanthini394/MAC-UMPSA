import java.awt.image.BufferedImage;
import java.io.File;
import javax.imageio.ImageIO;
import com.google.zxing.*;
import com.google.zxing.common.HybridBinarizer;
public class VerifyRoomQr {
    public static void main(String[] paths) throws Exception {
        for (String path : paths) {
            BufferedImage image = ImageIO.read(new File(path));
            int w=image.getWidth(), h=image.getHeight();
            int[] pixels=image.getRGB(0,0,w,h,null,0,w);
            Result result=new MultiFormatReader().decode(new BinaryBitmap(new HybridBinarizer(new RGBLuminanceSource(w,h,pixels))));
            String code=new File(path).getName().replace(".png","");
            if (!result.getText().equals("NKR1:"+code)) throw new IllegalStateException("QR decode mismatch");
            System.out.println(code+": independently decoded correctly");
        }
    }
}
