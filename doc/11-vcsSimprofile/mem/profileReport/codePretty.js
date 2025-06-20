// JSLint declarations
/*global console, document, navigator, setTimeout, window */

/**
 * Split {@code codePretty} into multiple timeouts so as not to interfere with
 * UI events. If set to {@code false}, {@code codePretty()} is synchronous.
 */
window['PR_SHOULD_USE_CONTINUATION'] = true;

(function () {
  // Keyword lists for various languages.
  // We use things that coerce to strings to make them compact when minified
  // and to defeat aggressive optimizers that fold large string constants.

  // token style names. correspond to css classes
  /**
         * token style for a string literal
         *
         * @const
         */
  var PR_STRING = 'str';
  /**
         * token style for a keyword
         *
         * @const
         */
  var PR_KEYWORD = 'kwd';
  /**
         * token style for a comment
         *
         * @const
         */
  var PR_COMMENT = 'com';
  /**
         * token style for a type
         *
         * @const
         */
  var PR_TYPE = 'typ';
  /**
         * token style for a literal value. e.g. 1, null, true.
         *
         * @const
         */
  var PR_LITERAL = 'lit';
  /**
         * token style for a punctuation string.
         *
         * @const
         */
  var PR_PUNCTUATION = 'pun';
  /**
         * token style for a punctuation string.
         *
         * @const
         */
  var PR_PLAIN = 'pln';

  /**
         * token style for an sgml tag.
         *
         * @const
         */
  var PR_TAG = 'tag';
  /**
         * token style for a markup declaration such as a DOCTYPE.
         *
         * @const
         */
  var PR_DECLARATION = 'dec';
  /**
         * token style for embedded source.
         *
         * @const
         */
  var PR_SOURCE = 'src';
  /**
         * token style for an sgml attribute name.
         *
         * @const
         */
  var PR_ATTRIB_NAME = 'atn';
  /**
         * token style for an sgml attribute value.
         *
         * @const
         */
  var PR_ATTRIB_VALUE = 'atv';

  // Combine Prefix Patterns
  /**
         * Given a group of {@link RegExp}s, returns a {@code RegExp} that globally
         * matches the union of the sets of strings matched by the input RegExp.
         * Since it matches globally, if the input strings have a start-of-input
         * anchor (/^.../), it is ignored for the purposes of unioning.
         *
         * @param {Array.
         *            <RegExp>} regexs non multiline, non-global regexs.
         * @return {RegExp} a global regex.
         */
  function combinePrefixPatterns(regexs) {
    var capturedGroupIndex = 0;
    var needToFoldCase = false;
    var ignoreCase = false;
    for (var i = 0, n = regexs.length; i < n; ++i) {
      var regex = regexs[i];
      if (regex.ignoreCase) {
        ignoreCase = true;
      } else if (/[a-z]/i.test(regex.source.replace(
                     /\\u[0-9a-f]{4}|\\x[0-9a-f]{2}|\\[^ux]/gi, ''))) {
        needToFoldCase = true;
        ignoreCase = false;
        break;
      }
    }

    var escapeCharToCodeUnit = {
      'b': 8,
      't': 9,
      'n': 0xa,
      'v': 0xb,
      'f': 0xc,
      'r': 0xd
    };

    function decodeEscape(charsetPart) {
      var cc0 = charsetPart.charCodeAt(0);
      if (cc0 !== 92 /* \\ */) {
        return cc0;
      }
      var c1 = charsetPart.charAt(1);
      cc0 = escapeCharToCodeUnit[c1];
      if (cc0) {
        return cc0;
      } else if ('0' <= c1 && c1 <= '7') {
        return parseInt(charsetPart.substring(1), 8);
      } else if (c1 === 'u' || c1 === 'x') {
        return parseInt(charsetPart.substring(2), 16);
      } else {
        return charsetPart.charCodeAt(1);
      }
    }

    function encodeEscape(charCode) {
      if (charCode < 0x20) {
        return (charCode < 0x10 ? '\\x0' : '\\x') + charCode.toString(16);
      }
      var ch = String.fromCharCode(charCode);
      if (ch === '\\' || ch === '-' || ch === '[' || ch === ']') {
        ch = '\\' + ch;
      }
      return ch;
    }

    function caseFoldCharset(charSet) {
      var charsetParts = charSet.substring(1, charSet.length - 1).match(
          new RegExp(
              '\\\\u[0-9A-Fa-f]{4}'
              + '|\\\\x[0-9A-Fa-f]{2}'
              + '|\\\\[0-3][0-7]{0,2}'
              + '|\\\\[0-7]{1,2}'
              + '|\\\\[\\s\\S]'
              + '|-'
              + '|[^-\\\\]',
              'g'));
      var groups = [];
      var ranges = [];
      var inverse = charsetParts[0] === '^';
      for (var i = inverse ? 1 : 0, n = charsetParts.length; i < n; ++i) {
        var p = charsetParts[i];
        if (/\\[bdsw]/i.test(p)) {  // Don't muck with named groups.
          groups.push(p);
        } else {
          var start = decodeEscape(p);
          var end;
          if (i + 2 < n && '-' === charsetParts[i + 1]) {
            end = decodeEscape(charsetParts[i + 2]);
            i += 2;
          } else {
            end = start;
          }
          ranges.push([start, end]);
          // If the range might intersect letters, then expand it.
          // This case handling is too simplistic.
          // It does not deal with non-latin case folding.
          // It works for latin source code identifiers though.
          if (!(end < 65 || start > 122)) {
            if (!(end < 65 || start > 90)) {
              ranges.push([Math.max(65, start) | 32, Math.min(end, 90) | 32]);
            }
            if (!(end < 97 || start > 122)) {
              ranges.push([Math.max(97, start) & ~32, Math.min(end, 122) & ~32]);
            }
          }
        }
      }

      // [[1, 10], [3, 4], [8, 12], [14, 14], [16, 16], [17, 17]]
      // -> [[1, 12], [14, 14], [16, 17]]
      ranges.sort(function (a, b) { return (a[0] - b[0]) || (b[1]  - a[1]); });
      var consolidatedRanges = [];
      var lastRange = [NaN, NaN];
      for (var i = 0; i < ranges.length; ++i) {
        var range = ranges[i];
        if (range[0] <= lastRange[1] + 1) {
          lastRange[1] = Math.max(lastRange[1], range[1]);
        } else {
          consolidatedRanges.push(lastRange = range);
        }
      }

      var out = ['['];
      if (inverse) { out.push('^'); }
      out.push.apply(out, groups);
      for (var i = 0; i < consolidatedRanges.length; ++i) {
        var range = consolidatedRanges[i];
        out.push(encodeEscape(range[0]));
        if (range[1] > range[0]) {
          if (range[1] + 1 > range[0]) { out.push('-'); }
          out.push(encodeEscape(range[1]));
        }
      }
      out.push(']');
      return out.join('');
    }

    function allowAnywhereFoldCaseAndRenumberGroups(regex) {
      // Split into character sets, escape sequences, punctuation strings
      // like ('(', '(?:', ')', '^'), and runs of characters that do not
      // include any of the above.
      var parts = regex.source.match(
          new RegExp(
              '(?:'
              + '\\[(?:[^\\x5C\\x5D]|\\\\[\\s\\S])*\\]'  // a character set
              + '|\\\\u[A-Fa-f0-9]{4}'  // a unicode escape
              + '|\\\\x[A-Fa-f0-9]{2}'  // a hex escape
              + '|\\\\[0-9]+'  // a back-reference or octal escape
              + '|\\\\[^ux0-9]'  // other escape sequence
              + '|\\(\\?[:!=]'  // start of a non-capturing group
              + '|[\\(\\)\\^]'  // start/emd of a group, or line start
              + '|[^\\x5B\\x5C\\(\\)\\^]+'  // run of other characters
              + ')',
              'g'));
      var n = parts.length;

      // Maps captured group numbers to the number they will occupy in
      // the output or to -1 if that has not been determined, or to
      // undefined if they need not be capturing in the output.
      var capturedGroups = [];

      // Walk over and identify back references to build the capturedGroups
      // mapping.
      for (var i = 0, groupIndex = 0; i < n; ++i) {
        var p = parts[i];
        if (p === '(') {
          // groups are 1-indexed, so max group index is count of '('
          ++groupIndex;
        } else if ('\\' === p.charAt(0)) {
          var decimalValue = +p.substring(1);
          if (decimalValue && decimalValue <= groupIndex) {
            capturedGroups[decimalValue] = -1;
          }
        }
      }

      // Renumber groups and reduce capturing groups to non-capturing groups
      // where possible.
      for (var i = 1; i < capturedGroups.length; ++i) {
        if (-1 === capturedGroups[i]) {
          capturedGroups[i] = ++capturedGroupIndex;
        }
      }
      for (var i = 0, groupIndex = 0; i < n; ++i) {
        var p = parts[i];
        if (p === '(') {
          ++groupIndex;
          if (capturedGroups[groupIndex] === undefined) {
            parts[i] = '(?:';
          }
        } else if ('\\' === p.charAt(0)) {
          var decimalValue = +p.substring(1);
          if (decimalValue && decimalValue <= groupIndex) {
            parts[i] = '\\' + capturedGroups[groupIndex];
          }
        }
      }

      // Remove any prefix anchors so that the output will match anywhere.
      // ^^ really does mean an anchored match though.
      for (var i = 0, groupIndex = 0; i < n; ++i) {
        if ('^' === parts[i] && '^' !== parts[i + 1]) { parts[i] = ''; }
      }

      // Expand letters to groups to handle mixing of case-sensitive and
      // case-insensitive patterns if necessary.
      if (regex.ignoreCase && needToFoldCase) {
        for (var i = 0; i < n; ++i) {
          var p = parts[i];
          var ch0 = p.charAt(0);
          if (p.length >= 2 && ch0 === '[') {
            parts[i] = caseFoldCharset(p);
          } else if (ch0 !== '\\') {
            // TODO: handle letters in numeric escapes.
            parts[i] = p.replace(
                /[a-zA-Z]/g,
                function (ch) {
                  var cc = ch.charCodeAt(0);
                  return '[' + String.fromCharCode(cc & ~32, cc | 32) + ']';
                });
          }
        }
      }

      return parts.join('');
    }

    var rewritten = [];
    for (var i = 0, n = regexs.length; i < n; ++i) {
      var regex = regexs[i];
      if (regex.global || regex.multiline) { throw new Error('' + regex); }
      rewritten.push(
          '(?:' + allowAnywhereFoldCaseAndRenumberGroups(regex) + ')');
    }

    return new RegExp(rewritten.join('|'), ignoreCase ? 'gi' : 'g');
  }


  // Extract Source Spans
  /**
         * Split markup into a string of source code and an array mapping ranges in
         * that string to the text nodes in which they appear.
         *
         * <p>
         * The HTML DOM structure:
         * </p>
         *
         * <pre>
         * (Element   &quot;p&quot;
         *   (Element &quot;b&quot;
         *     (Text  &quot;print &quot;))       ; #1
         *   (Text    &quot;'Hello '&quot;)      ; #2
         *   (Element &quot;br&quot;)            ; #3
         *   (Text    &quot;  + 'World';&quot;)) ; #4
         * </pre>
         *
         * <p>
         * corresponds to the HTML
         * {@code <p><b>print </b>'Hello '<br>  + 'World';</p>}.
         * </p>
         *
         * <p>
         * It will produce the output:
         * </p>
         *
         * <pre>
         * {
         *   sourceCode: &quot;print 'Hello '\n  + 'World';&quot;,
         *   //                 1         2
         *   //       012345678901234 5678901234567
         *   spans: [0, #1, 6, #2, 14, #3, 15, #4]
         * }
         * </pre>
         *
         * <p>
         * where #1 is a reference to the {@code "print "} text node above, and so
         * on for the other text nodes.
         * </p>
         *
         * <p>
         * The {@code} spans array is an array of pairs. Even elements are the start
         * indices of substrings, and odd elements are the text nodes (or BR
         * elements) that contain the text for those substrings. Substrings continue
         * until the next index or the end of the source.
         * </p>
         *
         * @param {Node}
         *            node an HTML DOM subtree containing source-code.
         * @return {Object} source code and the text nodes in which they occur.
         */
  function extractSourceSpans(node) {
    var chunks = [];
    var length = 0;
    var spans = [];
    var k = 0;

    var whitespace;
    if (node.currentStyle) {
      whitespace = node.currentStyle.whiteSpace;
    } else if (window.getComputedStyle) {
      whitespace = document.defaultView.getComputedStyle(node, null)
          .getPropertyValue('white-space');
    }
    var isPreformatted = whitespace && 'pre' === whitespace.substring(0, 3);

    function walk(node) {
      switch (node.nodeType) {
        case 1:  // Element
          for (var child = node.firstChild; child; child = child.nextSibling) {
            walk(child);
          }
          var nodeName = node.nodeName;
          if ('BR' === nodeName || 'LI' === nodeName) {
            chunks[k] = '\n';
            spans[k << 1] = length++;
            spans[(k++ << 1) | 1] = node;
          }
          break;
        case 3: case 4:  // Text
          var text = node.nodeValue;
          if (text.length) {
            if (!isPreformatted) {
              text = text.replace(/[ \t\r\n]+/g, ' ');
            } else {
              text = text.replace(/\r\n?/g, '\n');  // Normalize newlines.
            }
            // TODO: handle tabs here?
            chunks[k] = text;
            spans[k << 1] = length;
            length += text.length;
            spans[(k++ << 1) | 1] = node;
          }
          break;
      }
    }

    walk(node);

    return {
      sourceCode: chunks.join('').replace(/\n$/, ''),
      spans: spans
    };
  }


  /**
         * Apply the given language handler to sourceCode and add the resulting
         * decorations to out.
         *
         * @param {number}
         *            basePos the index of sourceCode within the chunk of source
         *            whose decorations are already present on out.
         */
  function appendDecorations(basePos, sourceCode, langHandler, out) {
    if (!sourceCode) { return; }
    var job = {
      sourceCode: sourceCode,
      basePos: basePos
    };
    langHandler(job);
    out.push.apply(out, job.decorations);
  }

  var notWs = /\S/;

  /**
         * Given an element, if it contains only one child element and any text
         * nodes it contains contain only space characters, return the sole child
         * element. Otherwise returns undefined.
         * <p>
         * This is meant to return the CODE element in {@code <pre><code ...>} when
         * there is a single child element that contains all the non-space textual
         * content, but not to return anything where there are multiple child
         * elements as in {@code <pre><code>...</code><code>...</code></pre>} or
         * when there is textual content.
         */
  function childContentWrapper(element) {
    var wrapper = undefined;
    for (var c = element.firstChild; c; c = c.nextSibling) {
      var type = c.nodeType;
      wrapper = (type === 1)  // Element Node
          ? (wrapper ? element : c)
          : (type === 3)  // Text Node
          ? (notWs.test(c.nodeValue) ? element : wrapper)
          : wrapper;
    }
    return wrapper === element ? undefined : wrapper;
  }

  /**
         * Given triples of [style, pattern, context] returns a lexing function, The
         * lexing function interprets the patterns to find token boundaries and
         * returns a decoration list of the form [index_0, style_0, index_1,
         * style_1, ..., index_n, style_n] where index_n is an index into the
         * sourceCode, and style_n is a style constant like PR_PLAIN. index_n-1 <=
         * index_n, and style_n-1 applies to all characters in
         * sourceCode[index_n-1:index_n].
         *
         * The stylePatterns is a list whose elements have the form [style : string,
         * pattern : RegExp, DEPRECATED, shortcut : string].
         *
         * Style is a style constant like PR_PLAIN, or can be a string of the form
         * 'lang-FOO', where FOO is a language extension describing the language of
         * the portion of the token in $1 after pattern executes. E.g., if style is
         * 'lang-lisp', and group 1 contains the text '(hello (world))', then that
         * portion of the token will be passed to the registered lisp handler for
         * formatting. The text before and after group 1 will be restyled using this
         * decorator so decorators should take care that this doesn't result in
         * infinite recursion. For example, the HTML lexer rule for SCRIPT elements
         * looks something like ['lang-js', /<[s]cript>(.+?)<\/script>/]. This may
         * match '<script>foo()<\/script>', which would cause the current
         * decorator to be called with '<script>' which would not match the same
         * rule since group 1 must not be empty, so it would be instead styled as
         * PR_TAG by the generic tag rule. The handler registered for the 'js'
         * extension would then be called with 'foo()', and finally, the current
         * decorator would be called with '<\/script>' which would not match the
         * original rule and so the generic tag rule would identify it as a tag.
         *
         * Pattern must only match prefixes, and if it matches a prefix, then that
         * match is considered a token with the same style.
         *
         * Context is applied to the last non-whitespace, non-comment token
         * recognized.
         *
         * Shortcut is an optional string of characters, any of which, if the first
         * character, gurantee that this pattern and only this pattern matches.
         *
         * @param {Array}
         *            shortcutStylePatterns patterns that always start with a known
         *            character. Must have a shortcut string.
         * @param {Array}
         *            fallthroughStylePatterns patterns that will be tried in order
         *            if the shortcut ones fail. May have shortcuts.
         *
         * @return {function (Object)} a function that takes source code and returns
         *         a list of decorations.
         */
  function createSimpleLexer(shortcutStylePatterns, fallthroughStylePatterns) {
    var shortcuts = {};
    var tokenizer;
    (function () {
      var allPatterns = shortcutStylePatterns.concat(fallthroughStylePatterns);
      var allRegexs = [];
      var regexKeys = {};
      for (var i = 0, n = allPatterns.length; i < n; ++i) {
        var patternParts = allPatterns[i];
        var shortcutChars = patternParts[3];
        if (shortcutChars) {
          for (var c = shortcutChars.length; --c >= 0;) {
            shortcuts[shortcutChars.charAt(c)] = patternParts;
          }
        }
        var regex = patternParts[1];
        var k = '' + regex;
        if (!regexKeys.hasOwnProperty(k)) {
          allRegexs.push(regex);
          regexKeys[k] = null;
        }
      }
      allRegexs.push(/[\0-\uffff]/);
      tokenizer = combinePrefixPatterns(allRegexs);
    })();

    var nPatterns = fallthroughStylePatterns.length;

    /**
         * Lexes job.sourceCode and produces an output array job.decorations of
         * style classes preceded by the position at which they start in
         * job.sourceCode in order.
         *
         * @param {Object}
         *            job an object like
         *
         * <pre>
         * {
         *    sourceCode: {string} sourceText plain text,
         *    basePos: {int} position of job.sourceCode in the larger chunk of
         *        sourceCode.
         * }
         * </pre>
         */
    var decorate = function (job) {
      var sourceCode = job.sourceCode, basePos = job.basePos;
      /**
                 * Even entries are positions in source in ascending order. Odd enties
                 * are style markers (e.g., PR_COMMENT) that run from that position
                 * until the end.
                 *
                 * @type {Array.<number|string>}
                 */
      var decorations = [basePos, PR_PLAIN];
      var pos = 0;  // index into sourceCode
      var tokens = sourceCode.match(tokenizer) || [];
      var styleCache = {};

      for (var ti = 0, nTokens = tokens.length; ti < nTokens; ++ti) {
        var token = tokens[ti];
        var style = styleCache[token];
        var match = void 0;

        var isEmbedded;
        if (typeof style === 'string') {
          isEmbedded = false;
        } else {
          var patternParts = shortcuts[token.charAt(0)];
          if (patternParts) {
            match = token.match(patternParts[1]);
            style = patternParts[0];
          } else {
            for (var i = 0; i < nPatterns; ++i) {
              patternParts = fallthroughStylePatterns[i];
              match = token.match(patternParts[1]);
              if (match) {
                style = patternParts[0];
                break;
              }
            }

            if (!match) {  // make sure that we make progress
              style = PR_PLAIN;
            }
          }

          isEmbedded = style.length >= 5 && 'lang-' === style.substring(0, 5);
          if (isEmbedded && !(match && typeof match[1] === 'string')) {
            isEmbedded = false;
            style = PR_SOURCE;
          }

          if (!isEmbedded) { styleCache[token] = style; }
        }

        var tokenStart = pos;
        pos += token.length;

        if (!isEmbedded) {
          decorations.push(basePos + tokenStart, style);
        } else {  // Treat group 1 as an embedded block of source code.
          var embeddedSource = match[1];
          var embeddedSourceStart = token.indexOf(embeddedSource);
          var embeddedSourceEnd = embeddedSourceStart + embeddedSource.length;
          if (match[2]) {
            // If embeddedSource can be blank, then it would match at the
            // beginning which would cause us to infinitely recurse on the
            // entire token, so we catch the right context in match[2].
            embeddedSourceEnd = token.length - match[2].length;
            embeddedSourceStart = embeddedSourceEnd - embeddedSource.length;
          }
          var lang = style.substring(5);
          // Decorate the left of the embedded source
          appendDecorations(
              basePos + tokenStart,
              token.substring(0, embeddedSourceStart),
              decorate, decorations);
          // Decorate the embedded source
          appendDecorations(
              basePos + tokenStart + embeddedSourceStart,
              embeddedSource,
              langHandlerForExtension(lang, embeddedSource),
              decorations);
          // Decorate the right of the embedded section
          appendDecorations(
              basePos + tokenStart + embeddedSourceEnd,
              token.substring(embeddedSourceEnd),
              decorate, decorations);
        }
      }
      job.decorations = decorations;
    };
    return decorate;
  }


  // NumberLines
  /**
         * Given a DOM subtree, wraps it in a list, and puts each line into its own
         * list item.
         *
         * @param {Node}
         *            node modified in place. Its content is pulled into an
         *            HTMLOListElement, and each line is moved into a separate list
         *            item. This requires cloning elements, so the input might not
         *            have unique IDs after numbering.
         */
  function numberLines(node, opt_startLineNum) {
    var lineBreak = /\r\n?|\n/;

    var document = node.ownerDocument;

    var whitespace;
    if (node.currentStyle) {
      whitespace = node.currentStyle.whiteSpace;
    } else if (window.getComputedStyle) {
      whitespace = document.defaultView.getComputedStyle(node, null)
          .getPropertyValue('white-space');
    }
    // If it's preformatted, then we need to split lines on line breaks
    // in addition to <BR>s.
    var isPreformatted = whitespace && 'pre' === whitespace.substring(0, 3);

    var li = document.createElement('LI');
    while (node.firstChild) {
      li.appendChild(node.firstChild);
    }
    // An array of lines. We split below, so this is initialized to one
    // un-split line.
    var listItems = [li];

    function walk(node) {
      switch (node.nodeType) {
        case 1:  // Element
          if ('BR' === node.nodeName) {
            breakAfter(node);
            // Discard the <BR> since it is now flush against a </LI>.
            if (node.parentNode) {
              node.parentNode.removeChild(node);
            }
          } else {
            for (var child = node.firstChild; child; child = child.nextSibling) {
              walk(child);
            }
          }
          break;
        case 3: case 4:  // Text
          if (isPreformatted) {
            var text = node.nodeValue;
            var match = text.match(lineBreak);
            if (match) {
              var firstLine = text.substring(0, match.index);
              node.nodeValue = firstLine;
              var tail = text.substring(match.index + match[0].length);
              if (tail) {
                var parent = node.parentNode;
                parent.insertBefore(
                    document.createTextNode(tail), node.nextSibling);
              }
              breakAfter(node);
              if (!firstLine) {
                // Don't leave blank text nodes in the DOM.
                node.parentNode.removeChild(node);
              }
            }
          }
          break;
      }
    }

    // Split a line after the given node.
    function breakAfter(lineEndNode) {
      // If there's nothing to the right, then we can skip ending the line
      // here, and move root-wards since splitting just before an end-tag
      // would require us to create a bunch of empty copies.
      while (!lineEndNode.nextSibling) {
        lineEndNode = lineEndNode.parentNode;
        if (!lineEndNode) { return; }
      }

      function breakLeftOf(limit, copy) {
        // Clone shallowly if this node needs to be on both sides of the break.
        var rightSide = copy ? limit.cloneNode(false) : limit;
        var parent = limit.parentNode;
        if (parent) {
          // We clone the parent chain.
          // This helps us resurrect important styling elements that cross
                        // lines.
          // E.g. in <i>Foo<br>Bar</i>
          // should be rewritten to <li><i>Foo</i></li><li><i>Bar</i></li>.
          var parentClone = breakLeftOf(parent, 1);
          // Move the clone and everything to the right of the original
          // onto the cloned parent.
          var next = limit.nextSibling;
          parentClone.appendChild(rightSide);
          for (var sibling = next; sibling; sibling = next) {
            next = sibling.nextSibling;
            parentClone.appendChild(sibling);
          }
        }
        return rightSide;
      }

      var copiedListItem = breakLeftOf(lineEndNode.nextSibling, 0);

      // Walk the parent chain until we reach an unattached LI.
      for (var parent;
           // Check nodeType since IE invents document fragments.
           (parent = copiedListItem.parentNode) && parent.nodeType === 1;) {
        copiedListItem = parent;
      }
      // Put it on the list of lines for later processing.
      listItems.push(copiedListItem);
    }

    // Split lines while there are lines left to split.
    for (var i = 0;  // Number of lines that have been split so far.
         i < listItems.length;  // length updated by breakAfter calls.
         ++i) {
      walk(listItems[i]);
    }

    // Make sure numeric indices show correctly.
    if (opt_startLineNum === (opt_startLineNum|0)) {
      listItems[0].setAttribute('value', opt_startLineNum);
    }

    var ol = document.createElement('OL');
    ol.className = 'linenums';
    var offset = Math.max(0, ((opt_startLineNum - 1 /* zero index */)) | 0) || 0;
    for (var i = 0, n = listItems.length; i < n; ++i) {
      li = listItems[i];
      // Stick a class on the LIs so that stylesheets can
      // color odd/even rows, or any other row pattern that
      // is co-prime with 10.
      //li.className = 'L' + ((i + offset) % 10);
      li.className = 'L' + (i + offset + 1);
      if (!li.firstChild) {
        li.appendChild(document.createTextNode('\xA0'));
      }
      ol.appendChild(li);
    }

    node.appendChild(ol);
  }

  // Recombine Tags and Decorations
  /**
         * Breaks {@code job.sourceCode} around style boundaries in
         * {@code job.decorations} and modifies {@code job.sourceNode} in place.
         *
         * @param {Object}
         *            job like
         *
         * <pre>
         * {
         *    sourceCode: {string} source as plain text,
         *    spans: {Array.&lt;number|Node&gt;} alternating span start indices into source
         *       and the text node or element (e.g. {@code &lt;BR&gt;}) corresponding to that
         *       span.
         *    decorations: {Array.&lt;number|string} an array of style classes preceded
         *       by the position at which they start in job.sourceCode in order
         * }
         * </pre>
         *
         * @private
         */
  function recombineTagsAndDecorations(job) {
    var isIE = /\bMSIE\b/.test(navigator.userAgent);
    var newlineRe = /\n/g;

    var source = job.sourceCode;
    var sourceLength = source.length;
    // Index into source after the last code-unit recombined.
    var sourceIndex = 0;

    var spans = job.spans;
    var nSpans = spans.length;
    // Index into spans after the last span which ends at or before sourceIndex.
    var spanIndex = 0;

    var decorations = job.decorations;
    var nDecorations = decorations.length;
    // Index into decorations after the last decoration which ends at or before
    // sourceIndex.
    var decorationIndex = 0;

    // Remove all zero-length decorations.
    decorations[nDecorations] = sourceLength;
    var decPos, i;
    for (i = decPos = 0; i < nDecorations;) {
      if (decorations[i] !== decorations[i + 2]) {
        decorations[decPos++] = decorations[i++];
        decorations[decPos++] = decorations[i++];
      } else {
        i += 2;
      }
    }
    nDecorations = decPos;

    // Simplify decorations.
    for (i = decPos = 0; i < nDecorations;) {
      var startPos = decorations[i];
      // Conflate all adjacent decorations that use the same style.
      var startDec = decorations[i + 1];
      var end = i + 2;
      while (end + 2 <= nDecorations && decorations[end + 1] === startDec) {
        end += 2;
      }
      decorations[decPos++] = startPos;
      decorations[decPos++] = startDec;
      i = end;
    }

    nDecorations = decorations.length = decPos;

    var decoration = null;
    while (spanIndex < nSpans) {
      var spanStart = spans[spanIndex];
      var spanEnd = spans[spanIndex + 2] || sourceLength;

      var decStart = decorations[decorationIndex];
      var decEnd = decorations[decorationIndex + 2] || sourceLength;

      var end = Math.min(spanEnd, decEnd);

      var textNode = spans[spanIndex + 1];
      var styledText;
      if (textNode.nodeType !== 1  // Don't muck with <BR>s or <LI>s
          // Don't introduce spans around empty text nodes.
          && (styledText = source.substring(sourceIndex, end))) {
        // This may seem bizarre, and it is. Emitting LF on IE causes the
        // code to display with spaces instead of line breaks.
        // Emitting Windows standard issue linebreaks (CRLF) causes a blank
        // space to appear at the beginning of every line but the first.
        // Emitting an old Mac OS 9 line separator makes everything spiffy.
        if (isIE) { styledText = styledText.replace(newlineRe, '\r'); }
        textNode.nodeValue = styledText;
        var document = textNode.ownerDocument;
        var span = document.createElement('SPAN');
        span.className = decorations[decorationIndex + 1];
        var parentNode = textNode.parentNode;
        parentNode.replaceChild(span, textNode);
        span.appendChild(textNode);
        if (sourceIndex < spanEnd) {  // Split off a text node.
          spans[spanIndex + 1] = textNode
              // TODO: Possibly optimize by using '' if there's no flicker.
              = document.createTextNode(source.substring(end, spanEnd));
          parentNode.insertBefore(textNode, span.nextSibling);
        }
      }

      sourceIndex = end;

      if (sourceIndex >= spanEnd) {
        spanIndex += 2;
      }
      if (sourceIndex >= decEnd) {
        decorationIndex += 2;
      }
    }
  }


  /** Maps language-specific file extensions to handlers. */
  var langHandlerRegistry = {};
  /**
         * Register a language handler for the given file extensions.
         *
         * @param {function
         *            (Object)} handler a function from source code to a list of
         *            decorations. Takes a single argument job which describes the
         *            state of the computation. The single parameter has the form
         *            {@code { sourceCode: {string} as plain text. decorations:
         *            {Array.<number|string>} an array of style classes preceded by
         *            the position at which they start in job.sourceCode in order.
         *            The language handler should assigned this field. basePos:
         *            {int} the position of source in the larger source chunk. All
         *            positions in the output decorations array are relative to the
         *            larger source chunk. } }
         * @param {Array.
         *            <string>} fileExtensions
         */
  function registerLangHandler(handler, fileExtensions) {
    for (var i = fileExtensions.length; --i >= 0;) {
      var ext = fileExtensions[i];
      if (!langHandlerRegistry.hasOwnProperty(ext)) {
        langHandlerRegistry[ext] = handler;
      } else if (window['console']) {
        console['warn']('cannot override language handler %s', ext);
      }
    }
  }
  function langHandlerForExtension(extension, source) {
    return langHandlerRegistry[extension];
  }
 registerLangHandler(
      createSimpleLexer(
        [
         // Whitespace
         [PR_PLAIN, /^[\t\n\r \xA0]+/, null, '\t\n\r \xA0']
        ],
        [
         // String, character or bit string
         [PR_STRING, /^(?:[BOX]?"(?:[^\"]|""|\\")*"|'.')/i],
         // Comment, from two dashes until end of line.
         [PR_COMMENT, /^(?:\/\/[^\r\n]*)+|(?:\/\*[\s\S]*?(?:\*\/|$))+/],
         [PR_KEYWORD, /^(?:always|and|assign|begin|buf|bufif0|bufif1|case|casex|casez|cmos|deassign|default|defparam|disable|edge|else|end|endcase|endfunction|endmodule|endprimitive|endspecify|endtable|endtask|event|for|force|forever|fork|function|highz0|highz1|if|ifnone|initial|inout|input|integer|join|large|macromodule|medium|module|nand|negedge|nmos|nor|not|notif0|notif1|or|output|parameter|pmos|posedge|primitive|pull0|pull1|pulldown|pullup|rcmos|real|realtime|reg|release|repeat|rnmos|rpmos|rtran|rtranif0|rtranif1|scalared|small|specify|specparam|strong0|strong1|supply0|supply1|table|task|time|tran|tranif0|tranif1|tri|tri0|tri1|triand|trior|trireg|vectored|wait|wand|weak0|weak1|while|wire|wor|xnor|xor|accept_on|alias|always_comb|always_ff|always_latch|assert|assume|automatic|before|bind|bins|binsof|bit|break|byte|cell|chandle|checker|class|clocking|config|const|constraint|context|continue|cover|covergroup|coverpoint|cross|design|dist|do|endchecker|endclass|endclocking|endconfig|endgenerate|endgroup|endinterface|endpackage|endprogram|endproperty|endsequence|enum|eventually|expect|export|extends|extern|final|first_match|foreach|forkjoin|generate|genvar|global|iff|ignore_bins|illegal_bins|implies|import|incdir|include|inside|instance|int|interface|intersect|join_any|join_none|let|liblist|library|local|localparam|logic|longint|matches|modport|new|nexttime|noshowcancelled|null|package|packed|priority|program|property|protected|pulsestyle_ondetect|pulsestyle_onevent|pure|rand|randc|randcase|randsequence|ref|reject_on|restrict|return|s_always|s_eventually|s_nexttime|s_until|s_until_with|sequence|shortint|shortreal|showcancelled|signed|solve|static|string|strong|struct|super|sync_accept_on|sync_reject_on|tagged|this|throughout|timeprecision|timeunit|type|typedef|union|unique|unique0|unsigned|until|until_with|untyped|use|uwire|var|virtual|void|wait_order|weak|wildcard|with|within|define|ifdef|ifndef|endif|endprotected|function|new|this|class|endclass|type|extends)(?=[^\w-]|$)/i, null],
         // Type, predefined or standard
         [PR_TYPE, /^(?:bit|bit_vector|character|boolean|integer|real|time|string|severity_level|positive|natural|signed|unsigned|line|text|std_u?logic(?:_vector)?)(?=[^\w-]|$)/i, null],
         // Predefined attributes
         [PR_TYPE, /^\'(?:ACTIVE|ASCENDING|BASE|DELAYED|DRIVING|DRIVING_VALUE|EVENT|HIGH|IMAGE|INSTANCE_NAME|LAST_ACTIVE|LAST_EVENT|LAST_VALUE|LEFT|LEFTOF|LENGTH|LOW|PATH_NAME|POS|PRED|QUIET|RANGE|REVERSE_RANGE|RIGHT|RIGHTOF|SIMPLE_NAME|STABLE|SUCC|TRANSACTION|VAL|VALUE)(?=[^\w-]|$)/i, null],
         // Number, decimal or based literal
         [PR_LITERAL, /^\d+(?:_\d+)*(?:#[\w\\.]+#(?:[+\-]?\d+(?:_\d+)*)?|(?:\.\d+(?:_\d+)*)?(?:E[+\-]?\d+(?:_\d+)*)?)/i],
         // Identifier, basic or extended
         [PR_PLAIN, /^(?:[a-z]\w*|\\[^\\]*\\)/i],
         // Punctuation
         [PR_PUNCTUATION, /^[^\w\t\n\r \xA0\"\'][^\w\t\n\r \xA0\-\"\']*/]
        ]),
    ['v']);
  registerLangHandler(
      createSimpleLexer(
        [
         // Whitespace
         [PR_PLAIN, /^[\t\n\r \xA0]+/, null, '\t\n\r \xA0']
        ],
        [
         // String, character or bit string
         [PR_STRING, /^(?:[BOX]?"(?:[^\"]|""|\\")*"|'.')/i],
         // Comment, from two dashes until end of line.
         [PR_COMMENT, /^(?:\/\/[^\r\n]*)+|(?:\/\*[\s\S]*?(?:\*\/|$))+/],
         [PR_KEYWORD, /^(?:always|and|assign|begin|buf|bufif0|bufif1|case|casex|casez|cmos|deassign|default|defparam|disable|edge|else|end|endcase|endfunction|endmodule|endprimitive|endspecify|endtable|endtask|event|for|force|forever|fork|function|highz0|highz1|if|ifnone|initial|inout|input|integer|join|large|macromodule|medium|module|nand|negedge|nmos|nor|not|notif0|notif1|or|output|parameter|pmos|posedge|primitive|pull0|pull1|pulldown|pullup|rcmos|real|realtime|reg|release|repeat|rnmos|rpmos|rtran|rtranif0|rtranif1|scalared|small|specify|specparam|strong0|strong1|supply0|supply1|table|task|time|tran|tranif0|tranif1|tri|tri0|tri1|triand|trior|trireg|vectored|wait|wand|weak0|weak1|while|wire|wor|xnor|xor|accept_on|alias|always_comb|always_ff|always_latch|assert|assume|automatic|before|bind|bins|binsof|bit|break|byte|cell|chandle|checker|class|clocking|config|const|constraint|context|continue|cover|covergroup|coverpoint|cross|design|dist|do|endchecker|endclass|endclocking|endconfig|endgenerate|endgroup|endinterface|endpackage|endprogram|endproperty|endsequence|enum|eventually|expect|export|extends|extern|final|first_match|foreach|forkjoin|generate|genvar|global|iff|ignore_bins|illegal_bins|implies|import|incdir|include|inside|instance|int|interface|intersect|join_any|join_none|let|liblist|library|local|localparam|logic|longint|matches|modport|new|nexttime|noshowcancelled|null|package|packed|priority|program|property|protected|pulsestyle_ondetect|pulsestyle_onevent|pure|rand|randc|randcase|randsequence|ref|reject_on|restrict|return|s_always|s_eventually|s_nexttime|s_until|s_until_with|sequence|shortint|shortreal|showcancelled|signed|solve|static|string|strong|struct|super|sync_accept_on|sync_reject_on|tagged|this|throughout|timeprecision|timeunit|type|typedef|union|unique|unique0|unsigned|until|until_with|untyped|use|uwire|var|virtual|void|wait_order|weak|wildcard|with|within|define|ifdef|ifndef|endif|endprotected|function|new|this|class|endclass|type|extends)(?=[^\w-]|$)/i, null],
         // Type, predefined or standard
         [PR_TYPE, /^(?:bit|bit_vector|character|boolean|integer|real|time|string|severity_level|positive|natural|signed|unsigned|line|text|std_u?logic(?:_vector)?)(?=[^\w-]|$)/i, null],
         // Predefined attributes
         [PR_TYPE, /^\'(?:ACTIVE|ASCENDING|BASE|DELAYED|DRIVING|DRIVING_VALUE|EVENT|HIGH|IMAGE|INSTANCE_NAME|LAST_ACTIVE|LAST_EVENT|LAST_VALUE|LEFT|LEFTOF|LENGTH|LOW|PATH_NAME|POS|PRED|QUIET|RANGE|REVERSE_RANGE|RIGHT|RIGHTOF|SIMPLE_NAME|STABLE|SUCC|TRANSACTION|VAL|VALUE)(?=[^\w-]|$)/i, null],
         // Number, decimal or based literal
         [PR_LITERAL, /^\d+(?:_\d+)*(?:#[\w\\.]+#(?:[+\-]?\d+(?:_\d+)*)?|(?:\.\d+(?:_\d+)*)?(?:E[+\-]?\d+(?:_\d+)*)?)/i],
         // Identifier, basic or extended
         [PR_PLAIN, /^(?:[a-z]\w*|\\[^\\\n]*\\)/i],
         // Punctuation
         [PR_PUNCTUATION, /^[^\w\t\n\r \xA0\"\'][^\w\t\n\r \xA0\-\"\']*/]
        ]),
    ['sv']);
  registerLangHandler(
      createSimpleLexer(
        [
         // Whitespace
         [PR_PLAIN, /^[\t\n\r \xA0]+/, null, '\t\n\r \xA0']
        ],
        [
         // String, character or bit string
         [PR_STRING, /^(?:[BOX]?"(?:[^\"]|""|\\")*"|'.')/i],
         // Comment, from two dashes until end of line.
         [PR_COMMENT, /^(?:\/\/[^\r\n]*)+|(?:\/\*[\s\S]*?(?:\*\/|$))+/],
         [PR_KEYWORD, /^(?:abs|access|after|alias|all|and|architecture|array|assert|attribute|begin|block|body|buffer|bus|case|component|configuration|constant|disconnect|downto|else|elsif|end|entity|exit|file|for|function|generate|generic|group|guarded|if|impure|in|inertial|inout|is|label|library|linkage|literal|loop|map|mod|nand|new|next|nor|not|null|of|on|open|or|others|out|package|port|postponed|procedure|process|pure|range|record|register|reject|rem|report|return|rol|ror|select|severity|shared|signal|sla|sll|sra|srl|subtype|then|to|transport|type|unaffected|units|until|use|variable|wait|when|while|with|xnor|xor)(?=[^\w-]|$)/i, null],
         // Type, predefined or standard
         [PR_TYPE, /^(?:bit|bit_vector|character|boolean|integer|real|time|string|severity_level|positive|natural|signed|unsigned|line|text|std_u?logic(?:_vector)?)(?=[^\w-]|$)/i, null],
         // Predefined attributes
         [PR_TYPE, /^\'(?:ACTIVE|ASCENDING|BASE|DELAYED|DRIVING|DRIVING_VALUE|EVENT|HIGH|IMAGE|INSTANCE_NAME|LAST_ACTIVE|LAST_EVENT|LAST_VALUE|LEFT|LEFTOF|LENGTH|LOW|PATH_NAME|POS|PRED|QUIET|RANGE|REVERSE_RANGE|RIGHT|RIGHTOF|SIMPLE_NAME|STABLE|SUCC|TRANSACTION|VAL|VALUE)(?=[^\w-]|$)/i, null],
         // Number, decimal or based literal
         [PR_LITERAL, /^\d+(?:_\d+)*(?:#[\w\\.]+#(?:[+\-]?\d+(?:_\d+)*)?|(?:\.\d+(?:_\d+)*)?(?:E[+\-]?\d+(?:_\d+)*)?)/i],
         // Identifier, basic or extended
         [PR_PLAIN, /^(?:[a-z]\w*|\\[^\\]*\\)/i],
         // Punctuation
         [PR_PUNCTUATION, /^[^\w\t\n\r \xA0\"\'][^\w\t\n\r \xA0\-\"\']*/]
        ]),
    ['vhdl', 'vhd']);

  function applyDecorator(job) {
    var opt_langExtension = job.langExtension;

    try {
      // Extract tags, and convert the source code to plain text.
      var sourceAndSpans = extractSourceSpans(job.sourceNode);
      /**
                 * Plain text.
                 *
                 * @type {string}
                 */
      var source = sourceAndSpans.sourceCode;
      job.sourceCode = source;
      job.spans = sourceAndSpans.spans;
      job.basePos = 0;

      // Apply the appropriate language handler
      langHandlerForExtension(opt_langExtension, source)(job);

      // Integrate the decorations and tags back into the source code,
      // modifying the sourceNode in place.
      recombineTagsAndDecorations(job);
    } catch (e) {
      if ('console' in window) {
        console['log'](e && e['stack'] ? e['stack'] : e);
      }
    }
  }

  function codePretty(opt_whenDone) {
    //function byTagName(tn) { return document.getElementsByTagName(tn); }
    // fetch a list of nodes to rewrite
    //var codeSegments = byTagName('pre');
    var codeSegments = window.node.childNodes;
    var elements = [];

    for (var i = 0, n = codeSegments.length; i < n; ++i)
        elements.push(codeSegments[i]);

    codeSegments = null;

    var clock = Date;
    if (!clock['now']) {
      clock = { 'now': function () { return +(new Date); } };
    }

    // The loop is broken into a series of continuations to make sure that we
    // don't make the browser unresponsive when rewriting a large page.
    var k = 0;
    var codePrettyingJob;

    var langExtensionRe = /\blang(?:uage)?-([\w.]+)(?!\S)/;
    var codePrettyRe = /\bcodepretty\b/;

    function doWork() {
      var endTime = (window['PR_SHOULD_USE_CONTINUATION'] ? clock['now']() + 250 /* ms */ : Infinity);
      for (; k < elements.length && clock['now']() < endTime; k++) {
        var cs = elements[k];
        var className = cs.className;
        if (className.indexOf('codepretty') >= 0) {
          var langExtension = className.match(langExtensionRe);
          var wrapper;
          if (!langExtension && (wrapper = childContentWrapper(cs))
              && "CODE" === wrapper.tagName) {
            langExtension = wrapper.className.match(langExtensionRe);
          }

          if (langExtension) {
            langExtension = langExtension[1];
          }
          // make sure this is not nested in an already prettified element
          var nested = false;
          for (var p = cs.parentNode; p; p = p.parentNode) {
            if ((p.tagName === 'pre') &&
                p.className && p.className.indexOf('codepretty') >= 0) {
              nested = true;
              break;
            }
          }
          if (!nested) {
            // Look for a class like linenums or linenums:<n> where <n> is the
            // 1-indexed number of the first line.
            var lineNums = cs.className.match(/\blinenums\b(?::(\d+))?/);
            lineNums = lineNums
                  ? lineNums[1] && lineNums[1].length ? +lineNums[1] : true
                  : false;
            if (lineNums) { numberLines(cs, lineNums); }

            // do the pretty printing
            codePrettyingJob = {
              langExtension: langExtension,
              sourceNode: cs,
              numberLines: lineNums
            };
            applyDecorator(codePrettyingJob);
          }
        }
      }
      if (k < elements.length) {
        // finish up in a continuation
        setTimeout(doWork, 250);
      } else if (opt_whenDone) {
        opt_whenDone();
      }
    }

    doWork();
  }

  // Externs
  var PR = {};

  /**
         * @param {function
         *            (Object)} handler
         * @param {Array.
         *            <string>} fileExtensions
         */
  PR.registerLangHandler = function registerLangHandler(handler, fileExtensions) {};

  /**
         * @param {Array}
         *            shortcutStylePatterns
         * @param {Array}
         *            fallthroughStylePatterns
         * @return {function (Object)}
         */
  PR.createSimpleLexer = function createSimpleLexer(
    shortcutStylePatterns, fallthroughStylePatterns) {};

  PR.PR_ATTRIB_NAME = 'atn';
  PR.PR_ATTRIB_VALUE = 'atv';
  PR.PR_COMMENT = 'com';
  PR.PR_DECLARATION = 'dec';
  PR.PR_KEYWORD = 'kwd';
  PR.PR_LITERAL = 'lit';
  PR.PR_PLAIN = 'pln';
  PR.PR_PUNCTUATION = 'pun';
  PR.PR_SOURCE = 'src';
  PR.PR_STRING = 'str';
  PR.PR_TAG = 'tag';
  PR.PR_TYPE = 'typ';

   /**
         * Pretty print a chunk of code.
         *
         * @param {string}
         *            sourceCodeHtml code as html
         * @return {string} code as html, but prettier
         */
  window['codePretty'] = codePretty;
   /**
         * Contains functions for creating and registering new language handlers.
         *
         * @type {Object}
         */
  window['PR'] = {
        'createSimpleLexer': createSimpleLexer,
        'registerLangHandler': registerLangHandler,
        'PR_ATTRIB_NAME': PR_ATTRIB_NAME,
        'PR_ATTRIB_VALUE': PR_ATTRIB_VALUE,
        'PR_COMMENT': PR_COMMENT,
        'PR_DECLARATION': PR_DECLARATION,
        'PR_KEYWORD': PR_KEYWORD,
        'PR_LITERAL': PR_LITERAL,
        'PR_PLAIN': PR_PLAIN,
        'PR_PUNCTUATION': PR_PUNCTUATION,
        'PR_SOURCE': PR_SOURCE,
        'PR_STRING': PR_STRING,
        'PR_TAG': PR_TAG,
        'PR_TYPE': PR_TYPE
      };
})();
        