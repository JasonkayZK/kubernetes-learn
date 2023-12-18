package io.jasonkayzk.github.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * @author zk
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Book {
    private Long id;

    private String name;
}
