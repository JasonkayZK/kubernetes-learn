package io.jasonkayzk.github.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.InetAddress;
import java.net.UnknownHostException;

@RestController
public class HelloController {

    @GetMapping("/")
    public String index() throws UnknownHostException {
        return "Greetings from Spring Boot on: " + InetAddress.getLocalHost().getHostName() + "\n";
    }

}
