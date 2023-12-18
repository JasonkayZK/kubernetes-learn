# Deploy Kafka StatefulSet Integrate

Deploy Kafka StatefulSet Integrate.

<br/>

## **Local Test**

Use `@EmbeddedKafka` for local testing:

src/test/java/ApplicationTests.java
```java
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
```

Run project with dev profile(default).

Test:

```shell
curl -X POST -F 'name=Java' http://localhost:8080/book

2023-12-18 21:47:48.870  INFO 17950 --- [ad | producer-1] io.jasonkayzk.github.kafka.BookProducer  : 生产者成功发送消息到topic:my-topic2 partition:0的消息
2023-12-18 21:47:48.870  INFO 17950 --- [ad | producer-1] io.jasonkayzk.github.kafka.BookProducer  : 生产者成功发送消息到topic:my-topic partition:0的消息
2023-12-18 21:47:48.889  INFO 17950 --- [ntainer#0-0-C-1] io.jasonkayzk.github.kafka.BookConsumer  : 消费者消费topic:my-topic partition:0的消息 -> Book(id=1, name=Java)
2023-12-18 21:47:48.891  INFO 17950 --- [ntainer#1-0-C-1] io.jasonkayzk.github.kafka.BookConsumer  : 消费者消费topic:my-topic2 的消息 -> Book(id=2, name=Java)

curl -X POST -F 'name=Java' http://localhost:8080/book

2023-12-18 21:48:16.009  INFO 17950 --- [ad | producer-1] io.jasonkayzk.github.kafka.BookProducer  : 生产者成功发送消息到topic:my-topic partition:1的消息
2023-12-18 21:48:16.010  INFO 17950 --- [ntainer#0-0-C-1] io.jasonkayzk.github.kafka.BookConsumer  : 消费者消费topic:my-topic partition:1的消息 -> Book(id=3, name=Java)
2023-12-18 21:48:16.014  INFO 17950 --- [ad | producer-1] io.jasonkayzk.github.kafka.BookProducer  : 生产者成功发送消息到topic:my-topic2 partition:0的消息
2023-12-18 21:48:16.015  INFO 17950 --- [ntainer#1-0-C-1] io.jasonkayzk.github.kafka.BookConsumer  : 消费者消费topic:my-topic2 的消息 -> Book(id=4, name=Java)

curl -X POST -F 'name=Java' http://localhost:8080/book

2023-12-18 21:48:16.652  INFO 17950 --- [ad | producer-1] io.jasonkayzk.github.kafka.BookProducer  : 生产者成功发送消息到topic:my-topic2 partition:0的消息
2023-12-18 21:48:16.653  INFO 17950 --- [ad | producer-1] io.jasonkayzk.github.kafka.BookProducer  : 生产者成功发送消息到topic:my-topic partition:0的消息
2023-12-18 21:48:16.653  INFO 17950 --- [ntainer#1-0-C-1] io.jasonkayzk.github.kafka.BookConsumer  : 消费者消费topic:my-topic2 的消息 -> Book(id=6, name=Java)
2023-12-18 21:48:16.653  INFO 17950 --- [ntainer#0-0-C-1] io.jasonkayzk.github.kafka.BookConsumer  : 消费者消费topic:my-topic partition:0的消息 -> Book(id=5, name=Java)
```

<br/>

## **Deploy Zookeeper & Kafka Cluster**

Deploy:

```shell
helm install zookeeper bitnami/zookeeper \
  --namespace workspace --create-namespace \
  --set replicaCount=3 \
  --set service.type=NodePort \
  --set service.nodePorts.client="32181" \
  --set global.storageClass=my-storage
  
export ZOOKEEPER_SERVICE_NAME='zookeeper.workspace.svc.cluster.local'

# kafka
helm install kafka bitnami/kafka \
  --namespace workspace --create-namespace \
  --set global.storageClass=my-storage \
  --set broker.replicaCount=3 \
  --set controller.replicaCount=0 \
  --set zookeeper.enabled=false \
  --set kraft.enabled=false \
  --set externalZookeeper.servers=${ZOOKEEPER_SERVICE_NAME} \
  --set externalAccess.enabled=true \
  --set externalAccess.broker.service.type=NodePort \
  --set externalAccess.broker.service.nodePorts[0]=30092 \
  --set externalAccess.broker.service.nodePorts[1]=30093 \
  --set externalAccess.broker.service.nodePorts[2]=30094 \
  --set externalAccess.autoDiscovery.enabled=true \
  --set serviceAccount.create=true \
  --set rbac.create=true
```

Reference:

- [《在Kubernetes中部署Zookeeper和Kafka》](https://jasonkayzk.github.io/2023/12/15/%E5%9C%A8Kubernetes%E4%B8%AD%E9%83%A8%E7%BD%B2Zookeeper%E5%92%8CKafka/) 

<br/>

## **Connect to the cluster**

Use Secrets:

deploy/deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-deploy-app
  namespace: workspace # 声明工作空间，默认为default
spec:
  replicas: 3
  selector:
    matchLabels:
      name: java-deploy-app
  template:
    metadata:
      labels:
        name: java-deploy-app
    spec:
      containers:
        - name: java-deploy-container
          image: jasonkay/java-deploy-app:v1.0.1
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080 # containerPort是声明容器内部的port
          env: # 将Secrets挂载为环境变量
            - name: KAFKA_USER
              value: 'user1'
            - name: KAFKA_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: kafka-user-passwords
                  key: client-passwords
```

Configure:

src/main/java/io/jasonkayzk/github/configure/kafka/KafkaConfigure.java
```java
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
```

Producer:

src/main/java/io/jasonkayzk/github/kafka/BookProducer.java
```java
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
```

Consumer:

src/main/java/io/jasonkayzk/github/kafka/BookConsumer.java
```java
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
```

<br/>

## Build & push image

```shell
docker build -t jasonkay/java-deploy-app:v1.0.1 .

docker push jasonkay/java-deploy-app:v1.0.1
```

<br/>

## Deploy on k8s

```shell
kubectl apply -f deploy/deployment.yaml
```

<br/>

## Test

```shell
# Curl node port
curl -X POST -F 'name=Java' http://<k8s-node-ip>:32080/book
```
