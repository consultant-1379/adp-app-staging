package dslTest

import javaposse.jobdsl.dsl.ConfigurationMissingException
import javaposse.jobdsl.dsl.Item
import javaposse.jobdsl.dsl.JobConfigurationNotFoundException
import javaposse.jobdsl.dsl.MockJobManagement
import javaposse.jobdsl.dsl.NameNotProvidedException

/**
 * Read files from the source directory, save output files in the build directory
 */
class TestJobManagement extends MockJobManagement {
    File buildDir
    File sourceDir

    TestJobManagement(File buildDir, File sourceDir) {
        this.buildDir = buildDir
        this.sourceDir = sourceDir
    }

    @Override
    String getConfig(String jobName) throws JobConfigurationNotFoundException {
        try {
            new File(buildDir, "${jobName}.xml").text
        }
        catch (IOException ignored) {
            throw new JobConfigurationNotFoundException(jobName)
        }
        return null
    }

    @Override
    boolean createOrUpdateConfig(Item item, boolean ignoreExisting)
            throws NameNotProvidedException {
        saveFile("${item.name}.xml", item.xml)
        return true
    }

    @Override
    void createOrUpdateView(String viewName, String config, boolean ignoreExisting)
            throws NameNotProvidedException, ConfigurationMissingException {
        saveFile("${viewName}.xml", config)
    }

    void saveFile(String fileName, String text) {
        def output = new File(buildDir, fileName)
        output.parentFile.mkdirs()
        output.write(text)
    }

    @Override
    InputStream streamFileInWorkspace(String filePath) throws IOException {
        return new FileInputStream(inputFile(filePath))
    }

    @Override
    String readFileInWorkspace(String filePath) throws IOException {
        return inputFile(filePath).text
    }

    File inputFile(String fileName) {
        return new File(sourceDir, fileName)
    }
}
