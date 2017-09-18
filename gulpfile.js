var gulp = require('gulp');
var gutil = require('gulp-util');
var concat = require('gulp-concat');
var sass = require('gulp-sass');
var coffee = require('gulp-coffee');
var minifyCss = require('gulp-minify-css');
var rename = require('gulp-rename');
var wrap = require('gulp-wrap');
var uglify = require('gulp-uglify');
var spritesmith = require('gulp.spritesmith');

var paths = {
  sass: ['./scss/**/*.scss'],
  coffee: ['./coffee/**/*.coffee'],
  translations: ['./translations/*.json'],
  libraries: [
    './lib/ionic/js/ionic.bundle.min.js',
    './lib/angular-cache/dist/angular-cache.min.js',
    './lib/angular-translate/angular-translate.min.js'
  ]
};

gulp.task('default', ['sprites','sass', 'coffee', 'translations', 'libraries']);

gulp.task('sprites', function(done) {
  var spriteData = gulp.src('./images/sets/*.png').pipe(spritesmith({
    imgName: 'sets.png',
    imgPath: '../images/sets.png',
    cssName: 'sets.min.css',
    cssSpritesheetName: 'icon-sets',
    cssTemplate: './scss/sets-template.handlebars'
  }));
  spriteData.img.pipe(gulp.dest('./images/'));
  spriteData.css
    .pipe(minifyCss({keepSpecialComments: 0}))
    .pipe(gulp.dest('./css/'))
    .on('end', done);
});

gulp.task('sass', function(done) {
  gulp.src(paths.sass)
    .pipe(sass({errLogToConsole: true}))
    //.pipe(minifyCss({keepSpecialComments: 0}))
    .pipe(rename({extname: '.min.css'}))
    .pipe(gulp.dest('./css/'))
    .on('end', done);
});

gulp.task('coffee', function() {
  gulp.src(paths.coffee)
    .pipe(coffee({bare: true}).on('error', gutil.log))
    .pipe(uglify())
    .pipe(concat('app.min.js'))
    .pipe(gulp.dest('./js/'))
});

gulp.task('translations', function() {
  gulp.src(paths.translations)
    .pipe(wrap("$translateProvider.translations('<%= file.relative.split('.')[0] %>', <%= contents %>);",null,{parse:false}))
    .pipe(concat('translations.min.js'))
    .pipe(wrap('angular.module("judgebooth.translations", ["pascalprecht.translate"]).config(["$translateProvider", function($translateProvider) {<%= contents %>}]);'))
    .pipe(uglify())
    .pipe(gulp.dest('./js/'));
});

gulp.task('libraries', function() {
  gulp.src(paths.libraries)
    .pipe(concat('lib.min.js'))
    .pipe(gulp.dest('./js/'))
});

gulp.task('watch', ['default'], function() {
  gulp.watch(paths.sass, ['sass']);
  gulp.watch(paths.coffee, ['coffee']);
  gulp.watch(paths.translations, ['translations']);
});
