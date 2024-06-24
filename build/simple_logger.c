// File: Simple logger - simple_logger.c
// Author: Kevin Moore <admin@sbotnas.io>
// Created: 2024/04/28
// Modified: 2024/04/28
// License: MIT License

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <regex.h>
#include <pcre.h>

#define DEFAULT_LOG_FILE "/tmp/container_log.log"
#define DEFAULT_FILTER_FILE "/usr/bin/filter.txt"
#define TZ_FILE "/var/run/s6/container_environment/TZ"
#define DEBUG_FILE "/var/run/s6/container_environment/CONTAINER_DEBUG"
#define MAX_BUF 1024

typedef struct {
    char **patterns;
    size_t count;
} PatternList;

PatternList filters = {NULL, 0};
PatternList anonymizers = {NULL, 0};

void free_patterns(PatternList *list) {
    for (size_t i = 0; i < list->count; i++) {
        free(list->patterns[i]);
    }
    free(list->patterns);
}

int load_patterns(const char *filename) {
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        fprintf(stderr, "Unable to open filter file: %s\n", filename);
        return -1;
    }

    PatternList *current_list = NULL;
    char line[MAX_BUF];
    while (fgets(line, sizeof(line), fp)) {
        char *newline = strchr(line, '\n');
        if (newline) *newline = '\0'; // Remove newline character

        if (strcmp(line, "BEGIN FILTERS") == 0) {
            current_list = &filters;
            continue;
        } else if (strcmp(line, "END FILTERS") == 0 || strcmp(line, "END ANONYMIZE") == 0) {
            current_list = NULL;
            continue;
        } else if (strcmp(line, "BEGIN ANONYMIZE") == 0) {
            current_list = &anonymizers;
            continue;
        }

        if (current_list && strlen(line) > 0) {
            current_list->patterns = realloc(current_list->patterns, (current_list->count + 1) * sizeof(char *));
            current_list->patterns[current_list->count] = strdup(line);
            current_list->count++;
        }
    }

    fclose(fp);
    return 0;
}

void set_timezone_from_file(const char *file_path) {
    FILE *file = fopen(file_path, "r");
    if (file == NULL) {
        perror("Failed to open timezone file");
        setenv("TZ", "UTC", 1);
        tzset();
        return;
    }

    char tzbuf[256];
    if (fgets(tzbuf, sizeof(tzbuf), file) != NULL) {
        tzbuf[strcspn(tzbuf, "\n")] = 0;
        setenv("TZ", tzbuf, 1);
    } else {
        setenv("TZ", "UTC", 1);
    }
    tzset();
    fclose(file);
}

int should_filter(const char *line, int enable_filtering) {
    if (!enable_filtering) {
        return 0; // If filtering is disabled, always return 'do not filter'
    }

    regex_t regex;
    int reti;

    // Check against each filter pattern
    for (size_t i = 0; i < filters.count; i++) {
        reti = regcomp(&regex, filters.patterns[i], 0);
        if (reti) {
            fprintf(stderr, "Could not compile regex\n");
            continue;
        }
        reti = regexec(&regex, line, 0, NULL, 0);
        regfree(&regex);
        if (!reti) {
            return 1; // Match found, filter this line
        }
    }
    return 0; // No match found, do not filter this line
}

int is_debug_enabled() {
    FILE *file = fopen(DEBUG_FILE, "r");
    if (file == NULL) {
        return 0; // Assume debugging is disabled if file cannot be opened
    }

    char dbgval[10];
    if (fgets(dbgval, sizeof(dbgval), file) == NULL || dbgval[0] != '1') {
        fclose(file);
        return 0; // Debugging is disabled if s6 var file is empty or value is not '1'
    }

    fclose(file);
    return 1; // Debugging is enabled
}

void apply_anonymization(char *line) {
    for (size_t i = 0; i < anonymizers.count; i++) {
        const char *error;
        int erroffset;
        pcre *re = pcre_compile(anonymizers.patterns[i], PCRE_UTF8, &error, &erroffset, NULL);
        if (!re) {
            fprintf(stderr, "PCRE compilation failed at offset %d: %s\n", erroffset, error);
            continue;
        }

        int ovector[30]; // Output vector for substring information
        int rc;
        int offset = 0;
        int line_len = strlen(line);

        while ((rc = pcre_exec(re, NULL, line, line_len, offset, 0, ovector, sizeof(ovector)/sizeof(ovector[0]))) >= 0) {
            for (int j = ovector[0]; j < ovector[1]; j++) {
                line[j] = '*';  // Anonymize matched text
            }
            offset = ovector[1];
        }
        pcre_free(re);
    }
}

void timestamp(char *dest, size_t max_size, const char *prefix) {
    time_t now = time(NULL);
    struct tm t;
    localtime_r(&now, &t);

    int written = strftime(dest, max_size, "[%Y-%m-%d %H:%M:%S] ", &t);
    if (written > 0 && written < max_size) {
        snprintf(dest + written, max_size - written, "[%s] ", prefix);
    }
}

int main(int argc, char *argv[]) {
    const char *log_file_path = DEFAULT_LOG_FILE;
    const char *filter_file_path = DEFAULT_FILTER_FILE;
    int overwrite_log = 0;
    int debug_mode = is_debug_enabled();
    char debug_prefix[128] = "debug-";

    set_timezone_from_file(TZ_FILE);
    load_patterns(filter_file_path);

    if (debug_mode) {
        strcpy(debug_prefix, "debug-"); // Prepend "debug-" only if debugging is enabled
    } else {
        debug_prefix[0] = '\0'; // Make debug_prefix an empty string if debugging is not enabled
    }

    int opt;
    while ((opt = getopt(argc, argv, "l:f:o")) != -1) {
        switch (opt) {
            case 'l':
                log_file_path = optarg;
                break;
            case 'f':
                filter_file_path = optarg;
                break;
            case 'o':
                overwrite_log = 1;
                break;
            default:
                fprintf(stderr, "Usage: %s [-l logfile] [-f filterfile] [-o] <prefix> <filter_control> <command...>\n", argv[0]);
                return 1;
        }
    }

    FILE *log_fp = fopen(log_file_path, overwrite_log ? "w" : "a");
    if (!log_fp) {
        // If opening the specified log file fails, print an error and try the default log file
        fprintf(stderr, "Error opening log file %s, defaulting to %s\n", log_file_path, DEFAULT_LOG_FILE);
        log_fp = fopen(DEFAULT_LOG_FILE, overwrite_log ? "w" : "a");
        if (!log_fp) {
            perror("Error opening default log file");
            return 1;
        }
    }

    char command[MAX_BUF] = {0};
    for (int i = optind + 2; i < argc; i++) {
        strncat(command, argv[i], sizeof(command) - strlen(command) - 1);
        if (i < argc - 1) {
            strncat(command, " ", sizeof(command) - strlen(command) - 1);
        }
    }

    FILE *cmd_fp = popen(command, "r");
    if (!cmd_fp) {
        perror("Error executing command");
        fclose(log_fp);
        return 1;
    }

    char line[MAX_BUF];
    char timestamped_line[MAX_BUF * 2];

    while (fgets(line, sizeof(line), cmd_fp)) {
        if (debug_mode) {
            apply_anonymization(line);  // Apply anonymization if debugging is enabled
        }

        if (!debug_mode && should_filter(line, 1)) {
            continue; // Skip logging this line
        }

        char final_prefix[256];
        snprintf(final_prefix, sizeof(final_prefix), "%s%s", debug_prefix, argv[optind]);

        timestamp(timestamped_line, sizeof(timestamped_line), final_prefix);
        strcat(timestamped_line, line);

        fputs(timestamped_line, stdout);
        fflush(stdout);

        fputs(timestamped_line, log_fp);
        fflush(log_fp);
    }

    pclose(cmd_fp);
    fclose(log_fp);
    free_patterns(&filters);
    free_patterns(&anonymizers);

    return 0;
}
