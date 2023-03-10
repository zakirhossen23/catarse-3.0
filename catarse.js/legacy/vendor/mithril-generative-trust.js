import m from 'mithril';

/**
 * Convert a string to HTML entities
 */
String.prototype.toHtmlEntities = function() {
    return this.replace(/./gm, function(s) {
        return "&#" + s.charCodeAt(0) + ";";
    });
};

/**
 * Create string from HTML entities
 */
String.fromHtmlEntities = function(string) {
    return (string+"").replace(/&#\d+;/gm,function(s) {
        return String.fromCharCode(s.match(/\d+/gm)[0]);
    })
};

/**
 * @typedef {{tag: string, key: string, attrs: Object, children: VNode[], text: string, dom: Document, domSize: number, state: string, events: any[], instance: Document}} VNode  
 */

/**
 * @description Generates a mithril component tree based on parsed HTML provided.
 * @param {string} text 
 * @param {{tagsToFilter:string[], tagsFilterIsWhitelist:boolean, eliminateScriptTags:boolean = true}} options
 * @returns {VNode}
 */
export default function generativeTrust(text = '', options = {}, renderer = m) {
    const parser = new DOMParser();
    const parsedDom = parser.parseFromString(text, 'text/html');
    const children = parsedDom.body.childNodes;
    if (children.length > 0) {
        return createElementsFromDom(children, renderer);
    } else {
        return htmlentities(text);
    }
}

/**
 * @typedef RenderedNode
 * @property
 */

/**
 * @param {NodeList} nodes 
 * @param {(string, Object, RenderedNode | string) => RenderedNode} renderer 
 */
function createElementsFromDom(nodes, renderer) {
    
    const elements = [];
    
    for (let i = 0; i < nodes.length; i++) {
        const child = nodes.item(i);
        switch(child.nodeName) {
            case '#text': {
                elements.push(child.textContent);
                break;
            }

            default: {
                elements.push(createElementFromDom(child, renderer));
                break;
            }
        }
    }

    return elements;
}

/**
 * 
 * @param {Node} node 
 * @param {(string, Object, RenderedNode | string) => RenderedNode} renderer 
 */
function createElementFromDom(node, renderer) {
    const hasChildren = node.childNodes.length > 0;
    if (hasChildren) {
        return renderer(node.nodeName, createAttributesObject(node), createElementsFromDom(node.childNodes, renderer));
    } else {
        return renderer(node.nodeName, createAttributesObject(node));
    }
}

/**
 * 
 * @param {Node} node 
 */
function createAttributesObject(node) {
    const attributesObject = {};
    /** @type {NamedNodeMap} */
    const attributes = node.attributes;
    for (let i = 0; i < attributes.length; i++) {
        const attrib = attributes.item(i);
        attributesObject[attrib.name] = attrib.value;
    }
    return attributesObject;
}

function htmlentities(text) {
    return text
    .replace(/\&quot;/gi, '"')
    .replace(/\&apos;/gi, '\'')
    .replace(/\&amp;/gi, '&')
    .replace(/\&lt;/gi, '<')
    .replace(/\&gt;/gi, '>')
    .replace(/\&nbsp;/gi, '??')
    .replace(/\&iexcl;/gi, '??')
    .replace(/\&cent;/gi, '??')
    .replace(/\&pound;/gi, '??')
    .replace(/\&curren;/gi, '??')
    .replace(/\&yen;/gi, '??')
    .replace(/\&brvbar;/gi, '??')
    .replace(/\&sect;/gi, '??')
    .replace(/\&uml;/gi, '??')
    .replace(/\&copy;/gi, '??')
    .replace(/\&ordf;/gi, '??')
    .replace(/\&laquo;/gi, '??')
    .replace(/\&not;/gi, '??')
    .replace(/\&shy;/gi, '??')
    .replace(/\&reg;/gi, '??')
    .replace(/\&macr;/gi, '??')
    .replace(/\&deg;/gi, '??')
    .replace(/\&plusmn;/gi, '??')
    .replace(/\&sup2;/gi, '??')
    .replace(/\&sup3;/gi, '??')
    .replace(/\&acute;/gi, '??')
    .replace(/\&micro;/gi, '??')
    .replace(/\&para;/gi, '??')
    .replace(/\&middot;/gi, '??')
    .replace(/\&cedil;/gi, '??')
    .replace(/\&sup1;/gi, '??')
    .replace(/\&ordm;/gi, '??')
    .replace(/\&raquo;/gi, '??')
    .replace(/\&frac14;/gi, '??')
    .replace(/\&frac12;/gi, '??')
    .replace(/\&frac34;/gi, '??')
    .replace(/\&iquest;/gi, '??')
    .replace(/\&times;/gi, '??')
    .replace(/\&divide;/gi, '??')
    .replace(/\&Agrave;/gi, '??')
    .replace(/\&Aacute;/gi, '??')
    .replace(/\&Acirc;/gi, '??')
    .replace(/\&Atilde;/gi, '??')
    .replace(/\&Auml;/gi, '??')
    .replace(/\&Aring;/gi, '??')
    .replace(/\&AElig;/gi, '??')
    .replace(/\&Ccedil;/gi, '??')
    .replace(/\&Egrave;/gi, '??')
    .replace(/\&Eacute;/gi, '??')
    .replace(/\&Ecirc;/gi, '??')
    .replace(/\&Euml;/gi, '??')
    .replace(/\&Igrave;/gi, '??')
    .replace(/\&Iacute;/gi, '??')
    .replace(/\&Icirc;/gi, '??')
    .replace(/\&Iuml;/gi, '??')
    .replace(/\&ETH;/gi, '??')
    .replace(/\&Ntilde;/gi, '??')
    .replace(/\&Ograve;/gi, '??')
    .replace(/\&Oacute;/gi, '??')
    .replace(/\&Ocirc;/gi, '??')
    .replace(/\&Otilde;/gi, '??')
    .replace(/\&Ouml;/gi, '??')
    .replace(/\&Oslash;/gi, '??')
    .replace(/\&Ugrave;/gi, '??')
    .replace(/\&Uacute;/gi, '??')
    .replace(/\&Ucirc;/gi, '??')
    .replace(/\&Uuml;/gi, '??')
    .replace(/\&Yacute;/gi, '??')
    .replace(/\&THORN;/gi, '??')
    .replace(/\&szlig;/gi, '??')
    .replace(/\&agrave;/gi, '??')
    .replace(/\&aacute;/gi, '??')
    .replace(/\&acirc;/gi, '??')
    .replace(/\&atilde;/gi, '??')
    .replace(/\&auml;/gi, '??')
    .replace(/\&aring;/gi, '??')
    .replace(/\&aelig;/gi, '??')
    .replace(/\&ccedil;/gi, '??')
    .replace(/\&egrave;/gi, '??')
    .replace(/\&eacute;/gi, '??')
    .replace(/\&ecirc;/gi, '??')
    .replace(/\&euml;/gi, '??')
    .replace(/\&igrave;/gi, '??')
    .replace(/\&iacute;/gi, '??')
    .replace(/\&icirc;/gi, '??')
    .replace(/\&iuml;/gi, '??')
    .replace(/\&eth;/gi, '??')
    .replace(/\&ntilde;/gi, '??')
    .replace(/\&ograve;/gi, '??')
    .replace(/\&oacute;/gi, '??')
    .replace(/\&ocirc;/gi, '??')
    .replace(/\&otilde;/gi, '??')
    .replace(/\&ouml;/gi, '??')
    .replace(/\&oslash;/gi, '??')
    .replace(/\&ugrave;/gi, '??')
    .replace(/\&uacute;/gi, '??')
    .replace(/\&ucirc;/gi, '??')
    .replace(/\&uuml;/gi, '??')
    .replace(/\&yacute;/gi, '??')
    .replace(/\&thorn;/gi, '??')
    .replace(/\&yuml;/gi, '??')
    
}