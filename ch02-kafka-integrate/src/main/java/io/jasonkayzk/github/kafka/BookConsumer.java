package io.jasonkayzk.github.kafka;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jasonkayzk.github.entity.Book;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

/**
 * @author zk
 */
@Service
public class BookConsumer {

    @Value("${kafka.topic.my-topic}")
    private String myTopic;
    @Value("${kafka.topic.my-topic2}")
    private String myTopic2;

    private final Logger logger = LoggerFactory.getLogger(BookConsumer.class);

    private final ObjectMapper objectMapper = new ObjectMapper();

    @KafkaListener(topics = {"${kafka.topic.my-topic}"}, groupId = "group1", containerFactory = "bookContainerFactory")
    public void consumeMessage(ConsumerRecord<String, String> bookConsumerRecord) {
        try {
            Book book = objectMapper.readValue(bookConsumerRecord.value(), Book.class);
            logger.info("消费者消费topic:{} partition:{}的消息 -> {}", bookConsumerRecord.topic(), bookConsumerRecord.partition(), book.toString());
        } catch (JsonProcessingException e) {
            logger.error(e.toString());
        }
    }

    @KafkaListener(topics = {"${kafka.topic.my-topic2}"}, groupId = "group2", containerFactory = "bookContainerFactory")
    public void consumeMessage2(Book book) {
        logger.info("消费者消费topic:{} 的消息 -> {}", myTopic2, book.toString());
    }
}
