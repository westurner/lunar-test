#pragma once
#include <vector>
#include <string>
#include <utility>

struct Arguments
{
    std::vector<std::string> paths;
    std::string placeFile;
    bool noPlace = false;
    bool args = false;
    bool testMode = false;
    bool showHelp = false;
    bool showVersion = false;
    std::string logLevel = "info";
    int verboseCount = 0;
};


extern Arguments gArgs;
extern Arguments ParseArguments(int argc, char** argv);
extern std::pair<int, std::string> Stage_Initialization();
extern void Stage_ConfigInitialization();
extern bool Preflight_ValidatePaths();
extern void Cleanup();

extern int run_main(int argc, char** argv);
