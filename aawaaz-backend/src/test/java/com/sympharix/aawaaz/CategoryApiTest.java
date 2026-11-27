package com.sympharix.aawaaz;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class CategoryApiTest {

    @Autowired
    private MockMvc mvc;

    @Test
    void listsSixCategoriesHighestPriorityFirst() throws Exception {
        mvc.perform(get("/api/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(6))
                .andExpect(jsonPath("$[0].categoryKey").value("safety"))
                .andExpect(jsonPath("$[0].safetyCritical").value(true));
    }

    @Test
    void setPriorityUpdatesAndReorders() throws Exception {
        mvc.perform(put("/api/categories/other/priority")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"priority\":95}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categoryKey").value("other"))
                .andExpect(jsonPath("$.priority").value(95));

        // 'other' (95) now sits just below 'safety' (100), above 'health' (90)
        mvc.perform(get("/api/categories"))
                .andExpect(jsonPath("$[0].categoryKey").value("safety"))
                .andExpect(jsonPath("$[1].categoryKey").value("other"));
    }

    @Test
    void setPriorityUnknownCategoryIs404() throws Exception {
        mvc.perform(put("/api/categories/nope/priority")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"priority\":10}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void negativePriorityIsBadRequest() throws Exception {
        mvc.perform(put("/api/categories/leave/priority")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"priority\":-5}"))
                .andExpect(status().isBadRequest());
    }
}
