(function() {
  let str = '_at = {\n';
  for (let i = 0; i <= 1; i += 1/32) {
    const key = '0x' + i.toString(16);
    const value = '0x0.' + (Math.round(Math.atan(i)*32768)*2).toString(16).padStart(4,'0');
    str += `\t[${key}]=${value},\n`;
  }
  str += '}';
  console.log(str);
})();
