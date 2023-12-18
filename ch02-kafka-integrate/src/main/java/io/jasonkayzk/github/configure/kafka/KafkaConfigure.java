package io.jasonkayzk.github.configure.kafka;

import org.apache.kafka.clients.CommonClientConfigs;
import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.common.security.plain.PlainLoginModule;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.*;
import org.springframework.kafka.support.converter.RecordMessageConverter;
import org.springframework.kafka.support.converter.StringJsonMessageConverter;
import org.springframework.kafka.support.serializer.JsonDeserializer;
import org.springframework.kafka.support.serializer.JsonSerializer;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * @author zk
 */
@Configuration
public class KafkaConfigure {

    @Value("${spring.kafka.bootstrap-servers}")
    private List<String> bootstrapAddresses;

    @Value("${kafka.sasl-enable}")
    private boolean saslEnable;

    @Value("${KAFKA_USER}")
    private String kafkaUsername;

    @Value("${KAFKA_PASSWORD}")
    private String kafkaPassword;

    /**
     * Use Config in application.yaml
     */
    @Value("${kafka.topic.my-topic}")
    String myTopic;
    @Value("${kafka.topic.my-topic2}")
    String myTopic2;

    /**
     * Kafka connection config
     */
    @Bean
    public KafkaAdmin kafkaAdmin() {
        Map<String, Object> configs = new HashMap<>(8);
        configs.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapAddresses);

        if (saslEnable) {
            configs.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, "SASL_PLAINTEXT");
            configs.put(SaslConfigs.SASL_MECHANISM, "PLAIN");

            configs.put(SaslConfigs.SASL_JAAS_CONFIG, String.format(
                    "%s required username=\"%s\" " + "password=\"%s\";", PlainLoginModule.class.getName(), kafkaUsername, kafkaPassword
            ));
        }

        return new KafkaAdmin(configs);
    }

    @Bean
    public ProducerFactory<Object, Object> producerFactory() {
        Map<String, Object> configs = new HashMap<>(8);
        configs.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapAddresses);
        configs.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, JsonSerializer.class);
        configs.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, JsonSerializer.class);

        if (saslEnable) {
            configs.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, "SASL_PLAINTEXT");

            configs.put(SaslConfigs.SASL_MECHANISM, "PLAIN");
            configs.put(SaslConfigs.SASL_JAAS_CONFIG, String.format(
                    "%s required username=\"%s\" " + "password=\"%s\";", PlainLoginModule.class.getName(), kafkaUsername, kafkaPassword
            ));
        }

        return new DefaultKafkaProducerFactory<>(configs);
    }

    @Bean(name = "bookContainerFactory")
    public ConcurrentKafkaListenerContainerFactory<String, Object> kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, Object> factory = new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        return factory;
    }

    public ConsumerFactory<String, Object> consumerFactory() {
        Map<String, Object> configs = new HashMap<>(8);
        configs.put(JsonDeserializer.TRUSTED_PACKAGES, "*");
        configs.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapAddresses);
        configs.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, JsonDeserializer.class);
        configs.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, JsonDeserializer.class);
        configs.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        if (saslEnable) {
            configs.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, "SASL_PLAINTEXT");
            configs.put(SaslConfigs.SASL_MECHANISM, "PLAIN");
            configs.put(SaslConfigs.SASL_JAAS_CONFIG, String.format(
                    "%s required username='%s' " + "password='%s';", PlainLoginModule.class.getName(), kafkaUsername, kafkaPassword
            ));
        }

        return new DefaultKafkaConsumerFactory<>(configs);
    }

    /**
     * JSON消息转换器
     */
    @Bean
    public RecordMessageConverter jsonConverter() {
        return new StringJsonMessageConverter();
    }

    /**
     * 通过注入一个 NewTopic 类型的 Bean 来创建 topic，如果 topic 已存在，则会忽略。
     */
    @Bean
    public NewTopic myTopic() {
        return new NewTopic(myTopic, 2, (short) 1);
    }

    @Bean
    public NewTopic myTopic2() {
        return new NewTopic(myTopic2, 1, (short) 1);
    }
}
