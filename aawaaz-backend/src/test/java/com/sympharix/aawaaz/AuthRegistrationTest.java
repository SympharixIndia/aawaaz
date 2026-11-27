package com.sympharix.aawaaz;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AuthRegistrationTest {

    @Autowired
    private MockMvc mvc;

    @Test
    void seededManagerCanLogIn() throws Exception {
        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"admin\",\"password\":\"admin123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userType").value("MANAGER"))
                .andExpect(jsonPath("$.languageCode").value("en-IN"));
    }

    @Test
    void wrongPasswordIsUnauthorized() throws Exception {
        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"admin\",\"password\":\"wrong\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void registerWorkerThenLogIn() throws Exception {
        mvc.perform(post("/api/workers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"ravi","name":"Ravi","password":"1234",
                                 "profession":"operator","languageCode":"hi-IN"}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.userType").value("WORKER"))
                .andExpect(jsonPath("$.profession").value("operator"));

        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"ravi\",\"password\":\"1234\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userType").value("WORKER"));
    }

    @Test
    void duplicateUsernameIsConflict() throws Exception {
        String body = """
                {"username":"dup","name":"Dup","password":"1234",
                 "profession":"helper","languageCode":"en-IN"}""";
        mvc.perform(post("/api/workers").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated());
        mvc.perform(post("/api/workers").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isConflict());
    }

    @Test
    void invalidRegistrationIsBadRequest() throws Exception {
        mvc.perform(post("/api/workers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"\",\"password\":\"1234\"}"))
                .andExpect(status().isBadRequest());
    }
}
