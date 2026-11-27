package com.sympharix.aawaaz;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import com.jayway.jsonpath.JsonPath;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class RequestApiTest {

    @Autowired
    private MockMvc mvc;

    private long registerWorker(String username) throws Exception {
        String body = mvc.perform(post("/api/workers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"" + username + "\",\"name\":\"W\","
                                + "\"password\":\"1234\",\"profession\":\"operator\","
                                + "\"languageCode\":\"hi-IN\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return ((Number) JsonPath.read(body, "$.id")).longValue();
    }

    private long fileRequest(long workerId, String text, String category, String urgency)
            throws Exception {
        String body = mvc.perform(post("/api/requests")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"workerId\":" + workerId + ",\"originalText\":\"" + text
                                + "\",\"originalLanguage\":\"hi-IN\",\"categoryKey\":\"" + category
                                + "\",\"urgency\":\"" + urgency + "\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("OPEN"))
                .andExpect(jsonPath("$.translatedLanguage").value("en-IN"))
                .andReturn().getResponse().getContentAsString();
        return ((Number) JsonPath.read(body, "$.id")).longValue();
    }

    @Test
    void fileRequestStoresVerbatimAndTranslationTarget() throws Exception {
        long worker = registerWorker("w_file");
        fileRequest(worker, "chhutti chahiye", "leave", "NORMAL");
    }

    @Test
    void fileRequestWithUnknownWorkerIs404() throws Exception {
        mvc.perform(post("/api/requests")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"workerId\":999999,\"originalText\":\"x\","
                                + "\"originalLanguage\":\"hi-IN\",\"categoryKey\":\"leave\","
                                + "\"urgency\":\"NORMAL\"}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void fileRequestWithUnknownCategoryIs400() throws Exception {
        long worker = registerWorker("w_badcat");
        mvc.perform(post("/api/requests")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"workerId\":" + worker + ",\"originalText\":\"x\","
                                + "\"originalLanguage\":\"hi-IN\",\"categoryKey\":\"nope\","
                                + "\"urgency\":\"NORMAL\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void listingSortsSafetyAboveLeave() throws Exception {
        long worker = registerWorker("w_sort");
        fileRequest(worker, "chhutti", "leave", "NORMAL");
        fileRequest(worker, "aag lag gayi", "safety", "HIGH");

        String body = mvc.perform(get("/api/requests"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        List<String> cats = JsonPath.read(body, "$[*].categoryKey");
        int safetyIdx = cats.indexOf("safety");
        int leaveIdx = cats.indexOf("leave");
        assertTrue(safetyIdx >= 0 && leaveIdx >= 0);
        assertTrue(safetyIdx < leaveIdx, "safety should sort above leave");
    }

    @Test
    void workerFilterReturnsOnlyOwnRequests() throws Exception {
        long a = registerWorker("w_a");
        long b = registerWorker("w_b");
        fileRequest(a, "one", "leave", "NORMAL");
        fileRequest(a, "two", "health", "HIGH");
        fileRequest(b, "three", "advance", "NORMAL");

        mvc.perform(get("/api/requests").param("workerId", String.valueOf(a)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void updateSetsStatusAndComment() throws Exception {
        long worker = registerWorker("w_upd");
        long reqId = fileRequest(worker, "chhutti", "leave", "NORMAL");

        mvc.perform(patch("/api/requests/" + reqId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"RESOLVED\",\"managerComment\":\"Approved\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("RESOLVED"))
                .andExpect(jsonPath("$.managerComment").value("Approved"))
                .andExpect(jsonPath("$.commentedAt").isNotEmpty());
    }

    @Test
    void updateMissingRequestIs404() throws Exception {
        mvc.perform(patch("/api/requests/999999")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"RESOLVED\"}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void getByTicketReturnsTheRequest() throws Exception {
        long worker = registerWorker("w_ticket");
        long reqId = fileRequest(worker, "chhutti", "leave", "NORMAL");

        mvc.perform(get("/api/requests/" + reqId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value((int) reqId))
                .andExpect(jsonPath("$.workerName").value("W"))
                .andExpect(jsonPath("$.categoryKey").value("leave"))
                .andExpect(jsonPath("$.status").value("OPEN"));
    }

    @Test
    void getByUnknownTicketIs404() throws Exception {
        mvc.perform(get("/api/requests/999999"))
                .andExpect(status().isNotFound());
    }
}
