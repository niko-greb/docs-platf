inputPath = 'docs'
inputFiles = [
    [file: 'index.adoc', formats: ['html']],
    [file: 'MP/README.adoc', formats: ['html']],
    [file: 'POS/README.adoc', formats: ['html']],
    [file: 'shared/errors.adoc', formats: ['html']],
    [file: 'shared/headers-auth.adoc', formats: ['html']],
    [file: 'POS/requirements/Menu/Menu.adoc', formats: ['html']],
    [file: 'MP/api/schemas/Dish.adoc', formats: ['html']]
]
outputPath = 'build'

diagrams = [
    plantuml: [
        format: 'png',
        cache: true
    ]
]

// confluence = [
//     api          : 'https://your-domain.atlassian.net/wiki/rest/api/',
//     spaceKey     : 'DOCS',
//     ancestorId   : '123456',  // ID родительской страницы
//     createSubpages: true
// ]