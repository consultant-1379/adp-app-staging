package dslTest

import javaposse.jobdsl.dsl.*

JobManagement jobMgmt = new TestJobManagement(
        new File(System.properties.'dsl.output' ?: '.'),
        new File('.'))

args.each { fileName ->
    println(fileName)
//    def req = new ScriptRequest(fileName, null, new URL("file:///${System.properties.'user.dir'}/"))

    File file = new File(fileName)
    def items = new DslScriptLoader(jobMgmt).runScript(file.text)
}
