package com.sympharix.aawaaz.service;

/**
 * Translates text between languages. The real engine is wired in at Step B6;
 * for now a pass-through implementation is used so the request APIs are complete.
 */
public interface TranslationService {

    /** Translates {@code text} from {@code fromLang} into {@code toLang}. */
    String translate(String text, String fromLang, String toLang);
}
