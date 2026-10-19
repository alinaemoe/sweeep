allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Dev-machine workaround: the SDK's NDK 28.2 folder is an empty, broken
// download. Use the installed NDK 27 for every module. Remove once NDK 28.2
// is reinstalled properly.
subprojects {
    afterEvaluate {
        val ext = extensions.findByName("android")
        if (ext != null) {
            ext.javaClass.getMethod("setNdkVersion", String::class.java).invoke(ext, "27.1.12297006")
        }
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
