inputPath = 'docs'
inputFiles = [
    [file: 'index.adoc', formats: ['html']],
    [file: 'MP/README.adoc', formats: ['html']],
    [file: 'POS/README.adoc', formats: ['html']],
    [file: 'shared/errors.adoc', formats: ['html']],
    [file: 'shared/headers-auth.adoc', formats: ['html']],
]
outputPath = 'build'

diagrams = [
    plantuml: [
        format: 'png',
        cache: true
    ]
]