package com.sympharix.aawaaz.service;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

/**
 * Translation via the Sarvam hosted API (https://api.sarvam.ai/translate).
 *
 * <p>Sarvam's language codes match the app's locale codes exactly ({@code en-IN},
 * {@code hi-IN}, {@code bn-IN}), so they pass straight through. If no API key is
 * configured, or a call fails, this returns the original text unchanged — so request
 * filing never breaks on a translation hiccup (and tests run without network).
 */
@Service
public class SarvamTranslationService implements TranslationService {

    private static final Logger log = LoggerFactory.getLogger(SarvamTranslationService.class);

    private final RestClient client;
    private final String apiKey;
    private final String model;

    public SarvamTranslationService(
            @Value("${sarvam.base-url:https://api.sarvam.ai}") String baseUrl,
            @Value("${sarvam.api-key:}") String apiKey,
            @Value("${sarvam.model:sarvam-translate:v1}") String model) {
        this.client = RestClient.builder().baseUrl(baseUrl).build();
        this.apiKey = apiKey;
        this.model = model;
    }

    @Override
    public String translate(String text, String fromLang, String toLang) {
        if (text == null || text.isBlank()
                || fromLang == null || toLang == null || fromLang.equals(toLang)
                || apiKey.isBlank()) {
            return text;
        }
        try {
            Map<String, Object> body = Map.of(
                    "input", text,
                    "source_language_code", fromLang,
                    "target_language_code", toLang,
                    "model", model);
            @SuppressWarnings("unchecked")
            Map<String, Object> response = client.post()
                    .uri("/translate")
                    .header("api-subscription-key", apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(Map.class);
            Object translated = response == null ? null : response.get("translated_text");
            String result = translated == null ? null : translated.toString();
            // Fallback: if the API gave no usable translation, store the original text.
            return (result != null && !result.isBlank()) ? result : text;
        } catch (Exception e) {
            // Any Sarvam error (4xx/5xx, timeout, network) → store the original text.
            log.warn("Sarvam translate failed ({} -> {}): {}", fromLang, toLang, e.toString());
            return text;
        }
    }
}
