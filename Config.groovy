inputPath = 'docs'
inputFiles = [
    [file: 'index.adoc', formats: ['html']]
]
outputPath = 'build'

diagrams = [
    plantuml: [
        format: 'png',
        cache: true
    ]
]