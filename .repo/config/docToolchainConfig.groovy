// ==============================================
// docToolchainConfig.groovy
// Конфигурация doctoolchain для генерации диаграмм и HTML
// ==============================================

inputPath = 'docs'
outputPath = 'build/docs'
inputFiles = fileTree(dir: inputPath, include: '**/*.adoc').files

taskInputsDirs = ["${inputPath}/diagrams"]

docFormats = ['html5']

generateDiagrams = [
    plantUMLDir   : "${inputPath}/diagrams",
    outputDir     : "${inputPath}/diagrams",
    outputFileExt : 'png'
]
