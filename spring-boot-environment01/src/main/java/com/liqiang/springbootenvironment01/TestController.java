package com.liqiang.springbootenvironment01;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

/**
 * @Project maven-plugin-parent
 * @PackageName com.liqiang.springbootenvironment01
 * @ClassName TestController
 * @Author qiang.li
 * @Date 2021/5/14 4:34 下午
 * @Description TODO
 */
@Controller
public class TestController {
    @Value("${value}")
    private String value;
    @Value("${name:}")
    private String name;

    @RequestMapping("test")
    @ResponseBody
    public String value() {
        return value + "|" + name;
    }
}
