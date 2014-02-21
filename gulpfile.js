var gulp = require('gulp');
var gutil = require('gulp-util');
var coffee = require('gulp-coffee');
var concat = require('gulp-concat');
var uglify = require('gulp-uglify');
var rename = require('gulp-rename');
var wrap = require('gulp-wrap-amd');
var coffeelint = require('gulp-coffeelint');
var mocha = require('gulp-mocha');

var paths = {
  scripts: 'src/*.coffee',
  tests: 'test/*.coffee'
};

gulp.task('lint', function () {
  gulp.src(paths.scripts)
    .pipe(coffeelint())
    .pipe(coffeelint.reporter())
});

gulp.task('src', ['lint'], function () {
  gulp.src(paths.scripts)
    .pipe(coffee({bare: true}).on('error', gutil.log))
    .pipe(concat('univedo.js'))
    .pipe(wrap({
      deps: ["ws"],
      params: ["ws"],
      exports: 'exports'
    }))
    .pipe(gulp.dest('dist/'));
});

gulp.task('uglify', ['src'], function () {
  gulp.src('dist/univedo.js')
  .pipe(uglify())
  .pipe(rename('univedo.min.js'))
  .pipe(gulp.dest('dist/'));
});

function test() {
  return gulp.src(paths.tests)
    .pipe(mocha({
      reporter: 'spec'
    }));
}

gulp.task('test', ['src'], function () {
  return test().on('error', function (e) {
    throw e;
  });
});

gulp.task('test-no-crash', ['src'], function() {
  test().on('error', function() {})
});

gulp.task('watch', function () {
  gulp.watch([paths.scripts, paths.tests], ['test-no-crash']);
});

gulp.task('default', ['test', 'uglify']);
