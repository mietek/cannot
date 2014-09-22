<!doctype html>
<html $if(dev)$class="dev"$endif$ lang="en">
  <head>
    <meta charset="utf-8">
    <title>$title$$if(dev)$ (dev)$endif$</title>
    <meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=yes,minimal-ui">
    <base href="$if(base)$$base$$else$/$endif$">
    <link rel="icon" type="image/png" href="_images/favicon-48.png" sizes="48x48">
    <link rel="icon" type="image/png" href="_images/favicon-16.png" sizes="16x16">
    <link rel="icon" type="image/png" href="_images/favicon-32.png" sizes="32x32">
    <link rel="stylesheet" href="_stylesheets.css">
    <script src="_scripts.js"></script>
    $for(header-includes)$
      $header-includes$
    $endfor$
    $if(head)$$head$$endif$
  </head>
  <body $if(body-class)$class="$body-class$"$endif$>
    <header id="header" $if(header-class)$class="$header-class$"$endif$>
      <div class="wrapper">
        $for(include-before)$
        $include-before$
        $endfor$
        $if(header)$$header$$endif$
      </div>
    </header>
    <main id="main" $if(main-class)$class="$main-class$"$endif$>
      <div class="wrapper">
        $body$
      </div>
    </main>
    <footer id="footer" $if(footer-class)$class="$footer-class$"$endif$>
      <div class="wrapper">
        $if(footer)$$footer$$endif$
        $for(include-after)$
        $include-after$
        $endfor$
      </div>
    </footer>
    <!--[if lte IE 9]>
    <div id="what-browser" class="dark">
      <div class="wrapper">
        <p>Please update your browser. <a href="http://whatbrowser.org/">What browser?</a></p>
      </div>
    </div>
    <![endif]-->
  </body>
</html>
