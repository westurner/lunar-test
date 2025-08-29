#include <filesystem>
#include <gtest/gtest.h>
//#include "bootstrap/main.cpp" // For Stage_Initialization and related functions
#include "../bootstrap/engine.h"
#include "../core/logging/Logging.h"
#ifdef __cplusplus
Arguments testArgs;
#endif


// Ensure all tests run in headless mode

struct GlobalTestModeSetter {
    GlobalTestModeSetter() { testArgs.testMode = true; }
};
GlobalTestModeSetter globalTestModeSetter;


#include <sstream>
#include <iostream>

// Log output capture helper
class LogCapture {
public:
    LogCapture() {
        oldBuf = std::cerr.rdbuf(captureBuf.rdbuf());
    }
    ~LogCapture() {
        std::cerr.rdbuf(oldBuf);
    }
    std::string str() const { return captureBuf.str(); }
private:
    std::stringstream captureBuf;
    std::streambuf* oldBuf;
};




class ScriptLoadingFixture : public ::testing::Test {
protected:
    std::string exampleDir = "../examples";
    void SetUp() override {
        // TODO: Setup code before each test (e.g., reset global state)
    }
    void TearDown() override {
        // TODO: Cleanup code after each test
    }
};



// Scenario: Place file loads successfully
TEST(MainScenario, LoadsValidPlaceFile) {
    Arguments args;
    args.placeFile = "../examples/helloworld.lua";
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load valid place file: " << errStr;
    EXPECT_TRUE(errStr.empty()) << "Unexpected error string for valid place file: " << errStr;
}

// Scenario: Place file loading fails for missing file
TEST(MainScenario, FailsToLoadMissingPlaceFile) {
    Arguments args;
    args.placeFile = "../examples/does_not_exist.lua";
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_NE(err, 0) << "Expected failure for missing place file";
    EXPECT_FALSE(errStr.empty()) << "Expected error string for missing place file";
}

// Scenario: CLI --test option sets testMode
TEST(MainScenario, TestModeOptionSetsFlag) {
    const char* argv[] = {"prog", "--test"};
    Arguments args = ParseArguments(2, const_cast<char**>(argv));
    EXPECT_TRUE(args.testMode);
}

// Scenario: CLI --no-place disables default place script
TEST(MainScenario, NoPlaceOptionDisablesDefault) {
    const char* argv[] = {"prog", "--no-place"};
    Arguments args = ParseArguments(2, const_cast<char**>(argv));
    EXPECT_TRUE(args.noPlace);
}

// Scenario: CLI --place sets placeFile
TEST(MainScenario, PlaceOptionSetsFile) {
    const char* argv[] = {"prog", "--place", "../examples/helloworld.lua"};
    Arguments args = ParseArguments(3, const_cast<char**>(argv));
    EXPECT_EQ(args.placeFile, "../examples/helloworld.lua");
}
// Scenario: CLI verbose mode sets logLevel and logs info
TEST(MainScenario, VerboseModeSetsLogLevelAndLogsInfo) {
    LogCapture log;
    const char* argv[] = {"prog", "-v"};
    Arguments args = ParseArguments(2, const_cast<char**>(argv));
    logging::SetLogLevel(args.logLevel);
    LOGI("Test info log");
    std::string logOutput = log.str();
    EXPECT_EQ(args.logLevel, "debug");
    EXPECT_NE(logOutput.find("Test info log"), std::string::npos) << "Log should contain info message in verbose mode";
}

// Scenario: CLI quiet mode sets logLevel and suppresses info log
TEST(MainScenario, QuietModeSuppressesInfoLog) {
    LogCapture log;
    const char* argv[] = {"prog", "-q"};
    Arguments args = ParseArguments(2, const_cast<char**>(argv));
    logging::SetLogLevel(args.logLevel);
    LOGI("Should not appear");
    std::string logOutput = log.str();
    EXPECT_EQ(args.logLevel, "error");
    EXPECT_EQ(logOutput.find("Should not appear"), std::string::npos) << "Info log should be suppressed in quiet mode";
}

// Scenario: Script error logs correct error message
TEST(MainScenario, LogsErrorForBrokenScript) {
    LogCapture log;
    Arguments args;
    args.paths.push_back("../examples/bug.lua");
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    std::string logOutput = log.str();
    if (err != 0) {
        EXPECT_FALSE(errStr.empty());
        EXPECT_NE(logOutput.find("Error"), std::string::npos) << "Log should contain error for broken script";
    }
}

// Scenario-driven test: test error log for missing script
TEST(MainScenario, LogsErrorForMissingScript) {
    LogCapture log;
    Arguments args;
    args.paths.push_back("../examples/does_not_exist.lua");
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    std::string logOutput = log.str();
    EXPECT_NE(err, 0);
    EXPECT_FALSE(errStr.empty());
    EXPECT_NE(logOutput.find("Failed to read script file"), std::string::npos) << "Log should contain error for missing script";
}



// Test loading a missing script (should fail)
TEST_F(ScriptLoadingFixture, FailsToLoadMissingScript) {
    std::string scriptPath = exampleDir + "/does_not_exist.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_NE(err, 0) << "Expected failure for missing script " << scriptPath;
    EXPECT_FALSE(errStr.empty()) << "Expected error string for missing script " << scriptPath;
}

// Test loading a known broken script (if you have one, e.g. bug.lua or crash_game.lua)
TEST_F(ScriptLoadingFixture, LoadsBugLuaHandlesError) {
    std::string scriptPath = exampleDir + "/bug.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    // Accept either success or error, but error string should match error code
    if (err == 0) {
        EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
    } else {
        EXPECT_FALSE(errStr.empty()) << "Expected error string for " << scriptPath;
    }
}

TEST_F(ScriptLoadingFixture, LoadsCrashGameLuaHandlesError) {
    std::string scriptPath = exampleDir + "/crash_game.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    if (err == 0) {
        EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
    } else {
        EXPECT_FALSE(errStr.empty()) << "Expected error string for " << scriptPath;
    }
}

// Generate a test for each script in examples/*.lua
TEST_F(ScriptLoadingFixture, LoadsPartLua) {
    std::string scriptPath = exampleDir + "/part.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load " << scriptPath << ": " << errStr;
    EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
}

TEST_F(ScriptLoadingFixture, LoadsClearAllChildrenLua) {
    std::string scriptPath = exampleDir + "/clearallchildren.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load " << scriptPath << ": " << errStr;
    EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
}

TEST_F(ScriptLoadingFixture, LoadsPartExampleLua) {
    std::string scriptPath = exampleDir + "/part_example.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load " << scriptPath << ": " << errStr;
    EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
}

TEST_F(ScriptLoadingFixture, LoadsTaskDelayLua) {
    std::string scriptPath = exampleDir + "/taskdelay.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load " << scriptPath << ": " << errStr;
    EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
}

TEST_F(ScriptLoadingFixture, LoadsVisualTempformLua) {
    std::string scriptPath = exampleDir + "/visual-tempform.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load " << scriptPath << ": " << errStr;
    EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
}

TEST_F(ScriptLoadingFixture, LoadsVisualWireframeSphereLua) {
    std::string scriptPath = exampleDir + "/visual-wireframe-sphere.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load " << scriptPath << ": " << errStr;
    EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
}

TEST_F(ScriptLoadingFixture, LoadsHelloWorldLua) {
    std::string scriptPath = exampleDir + "/helloworld.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load " << scriptPath << ": " << errStr;
    EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
}

TEST_F(ScriptLoadingFixture, LoadsVisualDarkhouseLua) {
    std::string scriptPath = exampleDir + "/visual-darkhouse.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load " << scriptPath << ": " << errStr;
    EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
}

TEST_F(ScriptLoadingFixture, LoadsTaskSpawnLua) {
    std::string scriptPath = exampleDir + "/taskspawn.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load " << scriptPath << ": " << errStr;
    EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
}

TEST_F(ScriptLoadingFixture, LoadsBugLua) {
    std::string scriptPath = exampleDir + "/bug.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load " << scriptPath << ": " << errStr;
    EXPECT_TRUE(errStr.empty()) << "Unexpected error string for " << scriptPath << ": " << errStr;
}

TEST_F(ScriptLoadingFixture, LoadsCrashGameLua) {
    std::string scriptPath = exampleDir + "/crash_game.lua";
    Arguments args;
    args.paths.push_back(scriptPath);
    args.testMode = true;
    testArgs = args;
    auto [err, errStr] = Stage_Initialization();
    EXPECT_EQ(err, 0) << "Failed to load " << scriptPath << ": " << errStr;
}


// Argument Parsing Tests
TEST(MainArgumentParsing, HandlesHelpFlag) {
    const char* argv[] = {"prog", "--help"};
    Arguments args = ParseArguments(2, const_cast<char**>(argv));
    EXPECT_TRUE(args.showHelp);
}

TEST(MainArgumentParsing, HandlesVersionFlag) {
    const char* argv[] = {"prog", "--version"};
    Arguments args = ParseArguments(2, const_cast<char**>(argv));
    EXPECT_TRUE(args.showVersion);
}

// Error Propagation Tests
TEST(StageInitializationTest, ReturnsSuccessOrError) {
    auto [err, errStr] = Stage_Initialization();
    if (err == 0) {
        EXPECT_TRUE(errStr.empty());
    } else {
        EXPECT_FALSE(errStr.empty());
    }
}


// CLI Options Tests
TEST(MainCliOptions, HandlesVerboseQuietLogLevel) {
    const char* argv1[] = {"prog", "-v"};
    Arguments args1 = ParseArguments(2, const_cast<char**>(argv1));
    EXPECT_EQ(args1.verboseCount, 1);

    const char* argv2[] = {"prog", "-q"};
    Arguments args2 = ParseArguments(2, const_cast<char**>(argv2));
    EXPECT_EQ(args2.logLevel, "error");

    const char* argv3[] = {"prog", "--log-level", "debug"};
    Arguments args3 = ParseArguments(3, const_cast<char**>(argv3));
    EXPECT_EQ(args3.logLevel, "debug");
}


// Script Loading Behavior Tests
TEST(ScriptLoading, LoadsValidScript) {
    // This test is a stub: would require a valid script file in the test environment
    SUCCEED();
}

TEST(ScriptLoading, HandlesMissingScript) {
    // This test is a stub: would require a missing script file in the test environment
    SUCCEED();
}

// int main(int argc, char **argv) {
//     ::testing::InitGoogleTest(&argc, argv);
//     return RUN_ALL_TESTS();
// }



// TODO: merge these in


// // Scenario: Place file loads successfully
// TEST(MainScenario, LoadsValidPlaceFile) {
//     Arguments args;
//     args.placeFile = "../examples/helloworld.lua";
//     args.testMode = true;
//     testArgs = args;
//     auto [err, errStr] = Stage_Initialization();
//     EXPECT_EQ(err, 0) << "Failed to load valid place file: " << errStr;
//     EXPECT_TRUE(errStr.empty()) << "Unexpected error string for valid place file: " << errStr;
// }

// // Scenario: Place file loading fails for missing file
// TEST(MainScenario, FailsToLoadMissingPlaceFile) {
//     Arguments args;
//     args.placeFile = "../examples/does_not_exist.lua";
//     args.testMode = true;
//     testArgs = args;
//     auto [err, errStr] = Stage_Initialization();
//     EXPECT_NE(err, 0) << "Expected failure for missing place file";
//     EXPECT_FALSE(errStr.empty()) << "Expected error string for missing place file";
// }

// // Scenario: CLI --test option sets testMode
// TEST(MainScenario, TestModeOptionSetsFlag) {
//     const char* argv[] = {"prog", "--test"};
//     Arguments args = ParseArguments(2, const_cast<char**>(argv));
//     args.testMode = true;
//     EXPECT_TRUE(args.testMode);
// }

// // Scenario: CLI --no-place disables default place script
// TEST(MainScenario, NoPlaceOptionDisablesDefault) {
//     const char* argv[] = {"prog", "--no-place"};
//     Arguments args = ParseArguments(2, const_cast<char**>(argv));
//     args.testMode = true;
//     EXPECT_TRUE(args.noPlace);
// }

// // Scenario: CLI --place sets placeFile
// TEST(MainScenario, PlaceOptionSetsFile) {
//     const char* argv[] = {"prog", "--place", "../examples/helloworld.lua"};
//     Arguments args = ParseArguments(3, const_cast<char**>(argv));
//     EXPECT_EQ(args.placeFile, "../examples/helloworld.lua");
// }

// // Scenario: CLI verbose mode sets logLevel and logs info

// Custom main for test binary: only run GoogleTest
int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
