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

subprojects {
    val applyNamespace = Action<Project> {
        extensions.findByName("android")?.let {
            val android = it as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                android.namespace = "com.example.${project.name.replace("-", ".")}"
            }
        }

        // Patch AndroidManifest.xml to strip package="..." for AGP 8+ compatibility
        val manifestFile = file("src/main/AndroidManifest.xml")
        if (manifestFile.exists()) {
            try {
                var content = manifestFile.readText()
                if (content.contains("package=")) {
                    content = content.replace(Regex("""package="[^"]*""""), "")
                    manifestFile.writeText(content)
                    project.logger.lifecycle("Patched manifest for subproject: ${project.name} to remove package attribute")
                }
            } catch (e: Exception) {
                project.logger.warn("Failed to patch manifest for ${project.name}: $e")
            }
        }

        // Patch webview_flutter_android files to remove deprecated v1 embedding classes/methods
        if (project.name == "webview_flutter_android") {
            val webViewPluginFile = file("src/main/java/io/flutter/plugins/webviewflutter/WebViewFlutterPlugin.java")
            if (webViewPluginFile.exists()) {
                try {
                    var content = webViewPluginFile.readText()
                    val methodStart = content.indexOf("public static void registerWith")
                    if (methodStart != -1) {
                        val methodEnd = content.indexOf("  private void setUp", methodStart)
                        if (methodEnd != -1) {
                            content = content.substring(0, methodStart) + "\n  // registerWith removed\n\n" + content.substring(methodEnd)
                            webViewPluginFile.writeText(content)
                            project.logger.lifecycle("Patched WebViewFlutterPlugin.java to remove registerWith")
                        }
                    }
                } catch (e: Exception) {
                    project.logger.warn("Failed to patch WebViewFlutterPlugin.java: $e")
                }
            }

            val assetManagerFile = file("src/main/java/io/flutter/plugins/webviewflutter/FlutterAssetManager.java")
            if (assetManagerFile.exists()) {
                try {
                    var content = assetManagerFile.readText()
                    val classStart = content.indexOf("  static class RegistrarFlutterAssetManager")
                    if (classStart != -1) {
                        val classEnd = content.indexOf("  static class PluginBindingFlutterAssetManager", classStart)
                        if (classEnd != -1) {
                            content = content.substring(0, classStart) + "\n  // RegistrarFlutterAssetManager removed\n\n" + content.substring(classEnd)
                            assetManagerFile.writeText(content)
                            project.logger.lifecycle("Patched FlutterAssetManager.java to remove RegistrarFlutterAssetManager")
                        }
                    }
                } catch (e: Exception) {
                    project.logger.warn("Failed to patch FlutterAssetManager.java: $e")
                }
            }
        }
    }
    if (state.executed) {
        applyNamespace.execute(this)
    } else {
        afterEvaluate {
            applyNamespace.execute(this)
        }
    }
}
