package com.sympharix.aawaaz;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import com.sympharix.aawaaz.domain.Request;
import com.sympharix.aawaaz.domain.RequestStatus;
import com.sympharix.aawaaz.domain.Urgency;
import com.sympharix.aawaaz.domain.User;
import com.sympharix.aawaaz.domain.UserType;
import com.sympharix.aawaaz.repository.CategoryRepository;
import com.sympharix.aawaaz.repository.RequestRepository;
import com.sympharix.aawaaz.repository.UserRepository;

/** Verifies the JPA entities map correctly against the seeded schema. */
@SpringBootTest
@Transactional
class RepositoryTest {

    @Autowired
    private UserRepository users;
    @Autowired
    private CategoryRepository categories;
    @Autowired
    private RequestRepository requests;

    @Test
    void seededManagerLoadsThroughEntity() {
        Optional<User> admin = users.findByUsernameIgnoreCase("admin");
        assertTrue(admin.isPresent());
        assertEquals(UserType.MANAGER, admin.get().getUserType());
        assertEquals("en-IN", admin.get().getLanguageCode());
        assertNotNull(admin.get().getCreatedAt());
    }

    @Test
    void seededCategoriesLoadOrderedByPriority() {
        var ordered = categories.findAllByOrderByPriorityDesc();
        assertEquals(6, ordered.size());
        assertEquals("safety", ordered.get(0).getCategoryKey());
        assertTrue(ordered.get(0).isSafetyCritical());
    }

    @Test
    void savesWorkerAndRequestRoundTrip() {
        User worker = new User();
        worker.setUsername("ramesh");
        worker.setName("Ramesh");
        worker.setPasswordHash("hash");
        worker.setUserType(UserType.WORKER);
        worker.setProfession("operator");
        worker.setLanguageCode("hi-IN");
        worker = users.save(worker);
        assertNotNull(worker.getId());

        Request req = new Request();
        req.setWorkerId(worker.getId());
        req.setOriginalText("मेरे को कल 2 दिन के लिए छुट्टी चाहिए");
        req.setOriginalLanguage("hi-IN");
        req.setTranslatedText("I need 2 days leave from tomorrow");
        req.setTranslatedLanguage("en-IN");
        req.setCategoryKey("leave");
        req.setUrgency(Urgency.NORMAL);
        req = requests.save(req);
        assertNotNull(req.getId());
        assertNotNull(req.getCreatedAt());
        assertEquals(RequestStatus.OPEN, req.getStatus());

        var mine = requests.findByWorkerIdOrderByCreatedAtDesc(worker.getId());
        assertEquals(1, mine.size());
        assertEquals("leave", mine.get(0).getCategoryKey());

        assertTrue(users.existsByUsernameIgnoreCase("RAMESH"));
        assertFalse(users.existsByUsernameIgnoreCase("nobody"));
    }
}
