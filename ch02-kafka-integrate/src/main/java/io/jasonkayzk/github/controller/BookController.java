package io.jasonkayzk.github.controller;

import io.jasonkayzk.github.entity.Book;
import io.jasonkayzk.github.kafka.BookProducer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.atomic.AtomicLong;

@RestController
@RequestMapping(value = "/book")
public class BookController {

    @Value("${kafka.topic.my-topic}")
    String myTopic;
    @Value("${kafka.topic.my-topic2}")
    String myTopic2;

    private final BookProducer producer;

    private final AtomicLong atomicLong = new AtomicLong();

    BookController(BookProducer producer) {
        this.producer = producer;
    }

    @PostMapping
    public void sendMessageToKafkaTopic(@RequestParam("name") String name) {
        this.producer.sendMessage(myTopic, new Book(atomicLong.addAndGet(1), name));
        this.producer.sendMessage(myTopic2, new Book(atomicLong.addAndGet(1), name));
    }
}
