#include <cstdio>
#include <string>

#include "Logging.h"


namespace logging {

int gLogLevel = LOG_INFO;

void SetLogLevel(const std::string& level) {
    if (level == "error") gLogLevel = LOG_ERROR;
    else if (level == "warning") gLogLevel = LOG_WARNING;
    else if (level == "info") gLogLevel = LOG_INFO;
    else if (level == "debug") gLogLevel = LOG_DEBUG;
    else if (level == "trace") gLogLevel = LOG_ALL;
    else gLogLevel = LOG_INFO;
}

void VLog(int level, const char* fmt, va_list ap) {
    char body[2048];
    vsnprintf(body, sizeof(body), fmt, ap);
    TraceLog(level, body);
}

void Log(int level, const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    VLog(level, fmt, ap);
    va_end(ap);
}

} // namespace logging