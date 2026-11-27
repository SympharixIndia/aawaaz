package com.sympharix.aawaaz.service;

import org.springframework.stereotype.Service;

/**
 * Stub translation: returns the text unchanged (optionally tagged with the target
 * language so it is visibly "translated" in demos). Replaced by a real engine at B6.
 */
@Service
public class PassThroughTranslationService implements TranslationService {

    @Override
    public String translate(String text, String fromLang, String toLang) {
        if (text == null || fromLang == null || fromLang.equals(toLang)) {
            return text;
        }
        // Placeholder until B6 wires a real engine; keeps the original words.
        return text;
    }
}
