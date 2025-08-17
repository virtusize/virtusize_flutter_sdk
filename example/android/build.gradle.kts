allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Force compatible byte-buddy version to fix CI issues
    configurations.all {
        resolutionStrategy {
            force("net.bytebuddy:byte-buddy:1.12.22")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

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
