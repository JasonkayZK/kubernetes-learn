package io.jasonkayzk.github.kafka;

import org.apache.kafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.util.concurrent.ListenableFuture;

/**
 * @author zk
 */
@Service
public class BookProducer {

    private static final Logger logger = LoggerFactory.getLogger(BookProducer.class);

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public BookProducer(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void sendMessage(String topic, Object o) {
        // 分区编号最好为 null，交给 kafka 自己去分配
        ProducerRecord<String, Object> producerRecord = new ProducerRecord<>(topic, null, System.currentTimeMillis(), String.valueOf(o.hashCode()), o);

        ListenableFuture<SendResult<String, Object>> future = kafkaTemplate.send(producerRecord);
        future.addCallback(result -> {
                    if (result != null) {
                        logger.info("生产者成功发送消息到topic:{} partition:{}的消息", result.getRecordMetadata().topic(), result.getRecordMetadata().partition());
                    }
                },
                ex -> logger.error("生产者发送消失败，原因：{}", ex.getMessage()));
    }
}
