/**
 * @callback RenderCallback
 * @param {Object} item
 * @param {String} label
 * @param {Autocomplete} inst
 * @returns {string}
 */
/**
 * @callback ItemCallback
 * @param {Object} item
 * @param {Autocomplete} inst
 * @returns {void}
 */
/**
 * @callback ServerCallback
 * @param {Response} response
 * @param {Autocomplete} inst
 * @returns {Promise}
 */
/**
 * @callback FetchCallback
 * @param {Autocomplete} inst
 * @returns {void}
 */
/**
 * @typedef Config
 * @property {Boolean} showAllSuggestions Show all suggestions even if they don't match
 * @property {Number} suggestionsThreshold Number of chars required to show suggestions
 * @property {Number} maximumItems Maximum number of items to display
 * @property {Boolean} autoselectFirst Always select the first item
 * @property {Boolean} ignoreEnter Ignore enter if no items are selected (play nicely with autoselectFirst=0)
 * @property {Boolean} updateOnSelect Update input value on selection (doesn't play nice with autoselectFirst)
 * @property {Boolean} highlightTyped Highlight matched part of the label
 * @property {String} highlightClass Class added to the mark label
 * @property {Boolean} fullWidth Match the width on the input field
 * @property {Boolean} fixed Use fixed positioning (solve overflow issues)
 * @property {Boolean} fuzzy Fuzzy search
 * @property {Boolean} startsWith Must start with the string. Defaults to false (it matches any position).
 * @property {Boolean} fillIn Show fill in icon.
 * @property {Boolean} preventBrowserAutocomplete Additional measures to prevent browser autocomplete
 * @property {String} itemClass Applied to the dropdown item. Accepts space separated classes.
 * @property {Array} activeClasses By default: ["bg-primary", "text-white"]
 * @property {String} labelField Key for the label
 * @property {String} valueField Key for the value
 * @property {Array} searchFields Key for the search
 * @property {String} queryParam Key for the query parameter for server
 * @property {Array|Object} items An array of label/value objects or an object with key/values
 * @property {Function} source A function that provides the list of items
 * @property {Boolean} hiddenInput Create an hidden input which stores the valueField
 * @property {String} hiddenValue Populate the initial hidden value. Mostly useful with liveServer.
 * @property {String} clearControl Selector that will clear the input on click.
 * @property {String} datalist The id of the source datalist
 * @property {String} server Endpoint for data provider
 * @property {String} serverMethod HTTP request method for data provider, default is GET
 * @property {String|Object} serverParams Parameters to pass along to the server. You can specify a "related" key with the id of a related field.
 * @property {String} serverDataKey By default: data
 * @property {Object} fetchOptions Any other fetch options (https://developer.mozilla.org/en-US/docs/Web/API/fetch#syntax)
 * @property {Boolean} liveServer Should the endpoint be called each time on input
 * @property {Boolean} noCache Prevent caching by appending a timestamp
 * @property {Number} debounceTime Debounce time for live server
 * @property {String} notFoundMessage Display a no suggestions found message. Leave empty to disable
 * @property {RenderCallback} onRenderItem Callback function that returns the label
 * @property {ItemCallback} onSelectItem Callback function to call on selection
 * @property {ServerCallback} onServerResponse Callback function to process server response. Must return a Promise
 * @property {ItemCallback} onChange Callback function to call on change-event. Returns currently selected item if any
 * @property {FetchCallback} onBeforeFetch Callback function before fetch
 * @property {FetchCallback} onAfterFetch Callback function after fetch
 */
/**
 * @type {Config}
 */
const e={showAllSuggestions:false,suggestionsThreshold:1,maximumItems:0,autoselectFirst:true,ignoreEnter:false,updateOnSelect:false,highlightTyped:false,highlightClass:"",fullWidth:false,fixed:false,fuzzy:false,startsWith:false,fillIn:false,preventBrowserAutocomplete:false,itemClass:"",activeClasses:["bg-primary","text-white"],labelField:"label",valueField:"value",searchFields:["label"],queryParam:"query",items:[],source:null,hiddenInput:false,hiddenValue:"",clearControl:"",datalist:"",server:"",serverMethod:"GET",serverParams:{},serverDataKey:"data",fetchOptions:{},liveServer:false,noCache:true,debounceTime:300,notFoundMessage:"",onRenderItem:(e,t,s)=>t,onSelectItem:(e,t)=>{},onServerResponse:(e,t)=>e.json(),onChange:(e,t)=>{},onBeforeFetch:e=>{},onAfterFetch:e=>{}};const t="is-loading";const s="is-active";const i="show";const n="next";const o="prev";const r=new WeakMap;let a=0;let h=0;
/**
 * @param {Function} func
 * @param {number} timeout
 * @returns {Function}
 */function debounce(e,t=300){let s;return(...i)=>{clearTimeout(s);s=setTimeout((()=>{e.apply(this,i)}),t)}}
/**
 * @param {String} str
 * @returns {String}
 */function removeDiacritics(e){return e.normalize("NFD").replace(/[\u0300-\u036f]/g,"")}
/**
 * @param {String|Number} str
 * @returns {String}
 */function normalize(e){return e?removeDiacritics(e.toString()).toLowerCase():""}
/**
 * A simple fuzzy match algorithm that checks if chars are matched
 * in order in the target string
 *
 * @param {String} str
 * @param {String} lookup
 * @returns {Boolean}
 */function fuzzyMatch(e,t){if(e.indexOf(t)>=0)return true;let s=0;for(let i=0;i<t.length;i++){const n=t[i];if(n!=" "){s=e.indexOf(n,s)+1;if(s<=0)return false}}return true}
/**
 * @param {HTMLElement} el
 * @param {HTMLElement} newEl
 * @returns {HTMLElement}
 */function insertAfter(e,t){return e.parentNode.insertBefore(t,e.nextSibling)}
/**
 * @param {string} html
 * @returns {string}
 */function decodeHtml(e){var t=document.createElement("textarea");t.innerHTML=e;return t.value}
/**
 * @param {HTMLElement} el
 * @param {Object} attrs
 */function attrs(e,t){for(const[s,i]of Object.entries(t))e.setAttribute(s,i)}
/**
 * Add a zero width join between chars
 * @param {HTMLElement|Element} el
 */function zwijit(e){e.ariaLabel=e.innerText;e.innerHTML=e.innerText.split("").map((e=>e+"&zwj;")).join("")}function nested(e,t="window"){return e.split(".").reduce(((e,t)=>e[t]),t)}class Autocomplete{
/**
   * @param {HTMLInputElement} el
   * @param {Config|Object} config
   */
constructor(e,t={}){if(!(e instanceof HTMLElement)){console.error("Invalid element",e);return}r.set(e,this);a++;h++;this._searchInput=e;this._configure(t);this._preventInput=false;this._keyboardNavigation=false;this._searchFunc=debounce((()=>{this._loadFromServer(true)}),this._config.debounceTime);this._configureSearchInput();this._configureDropElement();if(this._config.fixed){document.addEventListener("scroll",this,true);window.addEventListener("resize",this)}const s=this._getClearControl();s&&s.addEventListener("click",this);["focus","change","blur","input","keydown"].forEach((e=>{this._searchInput.addEventListener(e,this)}));["mousemove","mouseleave"].forEach((e=>{this._dropElement.addEventListener(e,this)}));this._fetchData()}
/**
   * Attach to all elements matched by the selector
   * @param {string} selector
   * @param {Config|Object} config
   */
static init(e="input.autocomplete",t={}){
/**
     * @type {NodeListOf<HTMLInputElement>}
     */
const s=document.querySelectorAll(e);s.forEach((e=>{this.getOrCreateInstance(e,t)}))}
/**
   * @param {HTMLInputElement} el
   */static getInstance(e){return r.has(e)?r.get(e):null}
/**
   * @param {HTMLInputElement} el
   * @param {Object} config
   */static getOrCreateInstance(e,t={}){return this.getInstance(e)||new this(e,t)}dispose(){h--;["focus","change","blur","input","keydown"].forEach((e=>{this._searchInput.removeEventListener(e,this)}));["mousemove","mouseleave"].forEach((e=>{this._dropElement.removeEventListener(e,this)}));const e=this._getClearControl();e&&e.removeEventListener("click",this);if(this._config.fixed&&h<=0){document.removeEventListener("scroll",this,true);window.removeEventListener("resize",this)}this._dropElement.parentElement.removeChild(this._dropElement);r.delete(this._searchInput)}_getClearControl(){if(this._config.clearControl)return document.querySelector(this._config.clearControl)}
/**
   * @link https://github.com/lifaon74/events-polyfill/issues/10
   * @link https://gist.github.com/WebReflection/ec9f6687842aa385477c4afca625bbf4#handling-events
   * @param {Event} event
   */handleEvent=e=>{const t=["scroll","resize"];if(t.includes(e.type)){this._timer&&window.cancelAnimationFrame(this._timer);this._timer=window.requestAnimationFrame((()=>{this[`on${e.type}`](e)}))}else this[`on${e.type}`](e)};
/**
   * @param {Config|Object} config
   */
_configure(t={}){this._config=Object.assign({},e);const s={...t,...this._searchInput.dataset};const parseBool=e=>["true","false","1","0",true,false].includes(e)&&!!JSON.parse(e);for(const[t,i]of Object.entries(e)){if(s[t]===void 0)continue;const e=s[t];switch(typeof i){case"number":this._config[t]=parseInt(e);break;case"boolean":this._config[t]=parseBool(e);break;case"string":this._config[t]=e.toString();break;case"object":if(Array.isArray(i))if(typeof e==="string"){const s=e.includes("|")?"|":",";this._config[t]=e.split(s)}else this._config[t]=e;else this._config[t]=typeof e==="string"?JSON.parse(e):e;break;case"function":this._config[t]=typeof e==="string"?window[e]:e;break;default:this._config[t]=e;break}}}_configureSearchInput(){this._searchInput.autocomplete="off";this._searchInput.spellcheck=false;attrs(this._searchInput,{"aria-autocomplete":"list","aria-haspopup":"menu","aria-expanded":"false",role:"combobox"});if(this._searchInput.id&&this._config.preventBrowserAutocomplete){const e=document.querySelector(`[for="${this._searchInput.id}"]`);e&&zwijit(e)}this._hiddenInput=null;if(this._config.hiddenInput){this._hiddenInput=document.createElement("input");this._hiddenInput.type="hidden";this._hiddenInput.value=this._config.hiddenValue;this._hiddenInput.name=this._searchInput.name;this._searchInput.name="_"+this._searchInput.name;insertAfter(this._searchInput,this._hiddenInput)}}_configureDropElement(){this._dropElement=document.createElement("ul");this._dropElement.id="ac-menu-"+a;this._dropElement.classList.add("dropdown-menu","autocomplete-menu","p-0");this._dropElement.style.maxHeight="280px";this._config.fullWidth||(this._dropElement.style.maxWidth="360px");this._config.fixed&&(this._dropElement.style.position="fixed");this._dropElement.style.overflowY="auto";this._dropElement.style.overscrollBehavior="contain";this._dropElement.style.textAlign="unset";insertAfter(this._searchInput,this._dropElement);this._searchInput.setAttribute("aria-controls",this._dropElement.id)}onclick(e){e.target.matches(this._config.clearControl)&&this.clear()}oninput(e){if(!this._preventInput){this._hiddenInput&&(this._hiddenInput.value=null);this.showOrSearch()}}onchange(e){const t=this._searchInput.value;const s=Object.values(this._items).find((e=>e.label===t));this._config.onChange(s,this)}onblur(e){e.relatedTarget&&e.relatedTarget.classList.contains("modal")?this._searchInput.focus():setTimeout((()=>{this.hideSuggestions()}),100)}onfocus(e){this.showOrSearch()}
/**
   * keypress doesn't send arrow keys, so we use keydown
   * @param {KeyboardEvent} e
   */onkeydown(e){const t=e.keyCode||e.key;switch(t){case 13:case"Enter":if(this.isDropdownVisible()){const t=this.getSelection();t&&t.click();!t&&this._config.ignoreEnter||e.preventDefault()}break;case 38:case"ArrowUp":e.preventDefault();this._keyboardNavigation=true;this._moveSelection(o);break;case 40:case"ArrowDown":e.preventDefault();this._keyboardNavigation=true;this.isDropdownVisible()?this._moveSelection(n):this.showOrSearch(false);break;case 27:case"Escape":if(this.isDropdownVisible()){this._searchInput.focus();this.hideSuggestions()}break}}onmousemove(e){this._keyboardNavigation=false}onmouseleave(e){this.removeSelection()}onscroll(e){this._positionMenu()}onresize(e){this._positionMenu()}
/**
   * @param {String} k
   * @returns {Config}
   */
getConfig(e=null){return e!==null?this._config[e]:this._config}
/**
   * @param {String} k
   * @param {*} v
   */setConfig(e,t){this._config[e]=t}setData(e){this._items={};this._addItems(e)}enable(){this._searchInput.setAttribute("disabled","")}disable(){this._searchInput.removeAttribute("disabled")}
/**
   * @returns {boolean}
   */isDisabled(){return this._searchInput.hasAttribute("disabled")||this._searchInput.disabled||this._searchInput.hasAttribute("readonly")}
/**
   * @returns {boolean}
   */isDropdownVisible(){return this._dropElement.classList.contains(i)}clear(){this._searchInput.value="";this._hiddenInput&&(this._hiddenInput.value="")}
/**
   * @returns {HTMLElement}
   */
getSelection(){return this._dropElement.querySelector("a."+s)}removeSelection(){const e=this.getSelection();e&&e.classList.remove(...this._activeClasses())}
/**
   * @returns {Array}
   */_activeClasses(){return[...this._config.activeClasses,s]}
/**
   * @param {HTMLElement} li
   * @returns {Boolean}
   */_isItemEnabled(e){if(e.style.display==="none")return false;const t=e.firstElementChild;return t.tagName==="A"&&!t.classList.contains("disabled")}
/**
   * @param {String} dir
   * @param {*|HTMLElement} sel
   * @returns {HTMLElement}
   */_moveSelection(e=n,t=null){const s=this.getSelection();if(s){const i=e===n?"nextSibling":"previousSibling";t=s.parentNode;do{t=t[i]}while(t&&!this._isItemEnabled(t));if(t){s.classList.remove(...this._activeClasses());e===o?t.parentNode.scrollTop=t.offsetTop-t.parentNode.offsetTop:t.offsetTop>t.parentNode.offsetHeight-t.offsetHeight&&(t.parentNode.scrollTop+=t.offsetHeight)}else s&&(t=s.parentElement)}else{if(e===o)return t;if(!t){t=this._dropElement.firstChild;while(t&&!this._isItemEnabled(t))t=t.nextSibling}}if(t){const e=t.querySelector("a");e.classList.add(...this._activeClasses());this._searchInput.setAttribute("aria-activedescendant",e.id);this._config.updateOnSelect&&(this._searchInput.value=e.dataset.label)}else this._searchInput.setAttribute("aria-activedescendant","");return t}
/**
   * Do we have enough input to show suggestions ?
   * @returns {Boolean}
   */
_shouldShow(){return!this.isDisabled()&&this._searchInput.value.length>=this._config.suggestionsThreshold}
/**
   * Show suggestions or load them
   * @param {Boolean} check
   */showOrSearch(e=true){!e||this._shouldShow()?this._config.liveServer?this._searchFunc():this._config.source?this._config.source(this._searchInput.value,(e=>{this.setData(e);this._showSuggestions()})):this._showSuggestions():this.hideSuggestions()}
/**
   * @param {String} name
   * @returns {HTMLElement}
   */_createGroup(e){const t=this._createLi();const s=document.createElement("span");t.append(s);s.classList.add("dropdown-header","text-truncate");s.innerHTML=e;return t}
/**
   * @param {String} lookup
   * @param {Object} item
   * @returns {HTMLElement}
   */_createItem(e,t){let s=t.label;if(this._config.highlightTyped){const t=normalize(s).indexOf(e);t!==-1&&(s=s.substring(0,t)+`<mark class="${this._config.highlightClass}">${s.substring(t,t+e.length)}</mark>`+s.substring(t+e.length,s.length))}s=this._config.onRenderItem(t,s,this);const i=this._createLi();const n=document.createElement("a");i.append(n);n.id=this._dropElement.id+"-"+this._dropElement.children.length;n.classList.add("dropdown-item","text-truncate");this._config.itemClass&&n.classList.add(...this._config.itemClass.split(" "));n.setAttribute("data-value",t.value);n.setAttribute("data-label",t.label);n.setAttribute("tabindex","-1");n.setAttribute("role","menuitem");n.setAttribute("href","#");n.innerHTML=s;if(t.data)for(const[e,s]of Object.entries(t.data))n.dataset[e]=s;if(this._config.fillIn){const e=document.createElement("button");e.type="button";e.classList.add("btn","btn-link","border-0");e.innerHTML='<svg width="16" height="16" fill="currentColor" viewBox="0 0 16 16">\n      <path fill-rule="evenodd" d="M2 2.5a.5.5 0 0 1 .5-.5h6a.5.5 0 0 1 0 1H3.707l10.147 10.146a.5.5 0 0 1-.708.708L3 3.707V8.5a.5.5 0 0 1-1 0z"/>\n      </svg>';i.append(e);i.classList.add("d-flex","justify-content-between");e.addEventListener("click",(e=>{this._searchInput.value=t.label;this._searchInput.focus()}))}n.addEventListener("mouseenter",(e=>{if(!this._keyboardNavigation){this.removeSelection();i.querySelector("a").classList.add(...this._activeClasses())}}));n.addEventListener("mousedown",(e=>{e.preventDefault()}));n.addEventListener("click",(e=>{e.preventDefault();this._preventInput=true;this._searchInput.value=decodeHtml(t.label);this._hiddenInput&&(this._hiddenInput.value=t.value);this._config.onSelectItem(t,this);this.hideSuggestions();this._preventInput=false}));return i}_showSuggestions(){if(document.activeElement!=this._searchInput)return;const e=normalize(this._searchInput.value);this._dropElement.innerHTML="";const t=Object.keys(this._items);let s=0;let i=null;const o=[];for(let n=0;n<t.length;n++){const r=t[n];const a=this._items[r];const h=this._config.showAllSuggestions||e.length===0;let l=e.length==0&&this._config.suggestionsThreshold===0;!h&&e.length>0&&this._config.searchFields.forEach((t=>{const s=normalize(a[t]);let i=false;if(this._config.fuzzy)i=fuzzyMatch(s,e);else{const t=s.indexOf(e);i=this._config.startsWith?t===0:t>=0}i&&(l=true)}));const c=l||e.length===0;if(h||l){s++;if(a.group&&!o.includes(a.group)){const e=this._createGroup(a.group);this._dropElement.appendChild(e);o.push(a.group)}const t=this._createItem(e,a);!i&&c&&(i=t);this._dropElement.appendChild(t);if(this._config.maximumItems>0&&s>=this._config.maximumItems)break}}if(i&&this._config.autoselectFirst){this.removeSelection();this._moveSelection(n,i)}if(s===0)if(this._config.notFoundMessage){const e=this._createLi();e.innerHTML=`<span class="dropdown-item">${this._config.notFoundMessage}</span>`;this._dropElement.appendChild(e);this._showDropdown()}else this.hideSuggestions();else this._showDropdown()}
/**
   * @returns {HTMLLIElement}
   */_createLi(){const e=document.createElement("li");e.setAttribute("role","presentation");return e}_showDropdown(){this._dropElement.classList.add(i);this._dropElement.setAttribute("role","menu");attrs(this._searchInput,{"aria-expanded":"true"});this._positionMenu()}
/**
   * Show or hide suggestions
   * @param {Boolean} check
   */toggleSuggestions(e=true){this._dropElement.classList.contains(i)?this.hideSuggestions():this.showOrSearch(e)}hideSuggestions(){this._dropElement.classList.remove(i);attrs(this._searchInput,{"aria-expanded":"false"});this.removeSelection()}
/**
   * @returns {HTMLInputElement}
   */getInput(){return this._searchInput}
/**
   * @returns {HTMLUListElement}
   */getDropMenu(){return this._dropElement}_positionMenu(){const e=window.getComputedStyle(this._searchInput);const t=this._searchInput.getBoundingClientRect();const s=e.direction==="rtl";const i=this._config.fullWidth;const n=this._config.fixed;let o=null;let r=null;if(n){o=t.x;r=t.y+t.height;s&&!i&&(o-=this._dropElement.offsetWidth-t.width)}this._dropElement.style.transform="unset";i&&(this._dropElement.style.width=this._searchInput.offsetWidth+"px");o!==null&&(this._dropElement.style.left=o+"px");r!==null&&(this._dropElement.style.top=r+"px");const a=this._dropElement.getBoundingClientRect();const h=window.innerHeight;if(a.y+a.height>h){const e=i?t.height+4:t.height;this._dropElement.style.transform="translateY(calc(-100.1% - "+e+"px))"}}_fetchData(){this._items={};this._addItems(this._config.items);const e=this._config.datalist;if(e){const t=document.querySelector(`#${e}`);if(t){const e=Array.from(t.children).map((e=>{const t=e.getAttribute("value")??e.innerHTML.toLowerCase();const s=e.innerHTML;return{value:t,label:s}}));this._addItems(e)}else console.error(`Datalist not found ${e}`)}this._setHiddenVal();this._config.server&&!this._config.liveServer&&this._loadFromServer()}_setHiddenVal(){if(this._config.hiddenInput&&!this._config.hiddenValue)for(const[e,t]of Object.entries(this._items))t.label==this._searchInput.value&&(this._hiddenInput.value=e)}
/**
   * @param {Array|Object} src An array of items or a value:label object
   */_addItems(e){const t=Object.keys(e);for(let s=0;s<t.length;s++){const i=t[s];const n=e[i];if(n.group&&n.items){n.items.forEach((e=>e.group=n.group));this._addItems(n.items);continue}const o=typeof n==="string"?n:n.label;const r=typeof n!=="object"?{}:n;r.label=n[this._config.labelField]??o;r.value=n[this._config.valueField]??i;r.label&&(this._items[r.value]=r)}}
/**
   * @param {boolean} show
   */_loadFromServer(e=false){this._abortController&&this._abortController.abort();this._abortController=new AbortController;let s=this._searchInput.dataset.serverParams||{};typeof s=="string"&&(s=JSON.parse(s));const i=Object.assign({},this._config.serverParams,s);i[this._config.queryParam]=this._searchInput.value;this._config.noCache&&(i.t=Date.now());if(i.related){
/**
       * @type {HTMLInputElement}
       */
const e=document.getElementById(i.related);if(e){i.related=e.value;const t=e.getAttribute("name");t&&(i[t]=e.value)}}const n=new URLSearchParams(i);let o=this._config.server;let r=Object.assign(this._config.fetchOptions,{method:this._config.serverMethod||"GET",signal:this._abortController.signal});r.method==="POST"?r.body=n:o+="?"+n.toString();this._searchInput.classList.add(t);this._config.onBeforeFetch(this);fetch(o,r).then((e=>this._config.onServerResponse(e,this))).then((t=>{const s=nested(this._config.serverDataKey,t)||t;this.setData(s);this._setHiddenVal();this._abortController=null;e&&this._showSuggestions()})).catch((e=>{e.name==="AbortError"||this._abortController.signal.aborted||console.error(e)})).finally((e=>{this._searchInput.classList.remove(t);this._config.onAfterFetch(this)}))}}export{Autocomplete as default};

