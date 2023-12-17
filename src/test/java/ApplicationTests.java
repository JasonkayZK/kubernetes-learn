import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.test.context.junit4.SpringRunner;

import java.io.IOException;

@RunWith(SpringRunner.class)
@SpringBootTest(classes = ApplicationTests.class)
@EmbeddedKafka(count = 3, ports = {9092, 9093, 9094})
public class ApplicationTests {
    @Test
    public void contextLoads() throws IOException {
        System.in.read();
    }
}
