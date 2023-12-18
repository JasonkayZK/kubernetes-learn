package io.jasonkayzk.github.configure.kafka;

import lombok.Data;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.context.support.GenericWebApplicationContext;

import javax.annotation.PostConstruct;
import java.util.List;

@Configuration
public class KafkaTopicConfigure {

    private final TopicConfiguration configuration;

    private final GenericWebApplicationContext context;

    public KafkaTopicConfigure(TopicConfiguration configuration, GenericWebApplicationContext genericContext) {
        this.configuration = configuration;
        this.context = genericContext;
    }

    @PostConstruct
    public void init() {
        initializeBeans(configuration.getTopics());
    }

    private void initializeBeans(List<TopicConfiguration.Topic> topics) {
        topics.forEach(t -> context.registerBean(t.name, NewTopic.class, t::toNewTopic));
    }
}

@Data
@Configuration
@ConfigurationProperties(prefix = "kafka")
class TopicConfiguration {
    private List<Topic> topics;

    @Data
    static class Topic {
        String name;
        Integer numPartitions = 3;
        Short replicationFactor = 1;

        NewTopic toNewTopic() {
            return new NewTopic(this.name, this.numPartitions, this.replicationFactor);
        }
    }
}
