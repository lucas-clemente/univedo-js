module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    concat:
      dist:
        src: ['lib/univedo.js']
        dest: 'dist/univedo.js'

    uglify:
      dist:
        src: 'dist/univedo.js',
        dest: 'dist/univedo.min.js'

    coffee:
      glob_to_multiple:
        expand: true
        cwd: 'src'
        src: ['*.coffee']
        dest: 'lib'
        ext: '.js'

    nodeunit:
      files: ['test/**/*_test.coffee']

    watch:
      src:
        files: ['src/**/*.coffee']
        tasks: ['coffee']
      lib:
        files: ['lib/**/*.js']
        tasks: ['nodeunit']
      test:
        files: ['test/**/*.coffee']
        tasks: ['nodeunit']

  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-nodeunit'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'default', ['coffee', 'nodeunit', 'concat', 'uglify']
