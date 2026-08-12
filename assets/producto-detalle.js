(()=>{
  const $=selector=>document.querySelector(selector);
  const header=$("#header");
  const burger=$("#burger");
  const nav=$("#nav");
  const productsToggle=$(".has-sub>a");
  const productName=document.body.dataset.product;
  const whatsapp="593991570939";
  const updateHeader=()=>header.classList.toggle("scrolled",window.scrollY>40);
  const setMenuOpen=open=>{nav.classList.toggle("open",open);burger.setAttribute("aria-expanded",String(open));};
  updateHeader();
  addEventListener("scroll",updateHeader,{passive:true});
  burger.addEventListener("click",()=>setMenuOpen(!nav.classList.contains("open")));
  productsToggle.addEventListener("click",event=>{if(innerWidth<=780){event.preventDefault();event.currentTarget.closest(".has-sub").classList.toggle("open");}});
  nav.querySelectorAll("a").forEach(link=>link.addEventListener("click",()=>{if(innerWidth<=780&&link!==productsToggle){setMenuOpen(false);}}));
  $("#year").textContent=new Date().getFullYear();
  $("#wa").href="https://wa.me/"+whatsapp+"?text="+encodeURIComponent(`Hola, me interesa ${productName} de SueñoHotel.`);
  const quoteForm=$("#quote-form");
  quoteForm.addEventListener("submit",event=>{
    event.preventDefault();
    const data=new FormData(quoteForm);
    const lines=[`Hola, soy ${data.get("name")}.`,`Teléfono: ${data.get("phone")}.`];
    if(data.get("company")){lines.push(`Empresa o proyecto: ${data.get("company")}.`);}
    lines.push(`Necesito: ${data.get("message")}`);
    window.open("https://wa.me/"+whatsapp+"?text="+encodeURIComponent(lines.join("\n")),"_blank","noopener");
  });
})();
