module.exports = class ChineseTextSplitter {
  constructor({ chunkSize = 1000, chunkOverlap = 20 } = {}) {
    this.chunkSize = chunkSize;
    this.chunkOverlap = chunkOverlap;
  }

  splitText(text) {
    const separators = [
      /(?<=\n\s*(?=[(（]?[\d一二三四五六七八九十零]+[)）]?[ \t]*[、.])|[。！？]\s*\n|\n```)/,
      /(?<=\n\n|\.\s+)/,
      /(?<=[\n。！？])/,
      /(?<=[\]\}\)])/,
      /(?<=[；;,，])/,
      /(?<=[\.:\s])/,
      "",
    ];

    // 先大拆，拆完仍超出长度，再细拆
    const sepIx = 0;
    const sentences = text.split(separators[sepIx]).filter(s => s.trim());

    // 2. 动态合并句子块
    const chunkSize = this.chunkSize;
    const chunks = [];
    let currentChunk = [];
    let currentLength = 0;
    const maxLack = 80; //如果chunkSize是1000，则每段应大于920

    for (let sentence of sentences) {
      let wordCount = sentence.length;
      if (currentLength + wordCount > chunkSize) {
        const need = chunkSize - currentLength;
        if (need > maxLack) {
          //需要300，从后面拿len长度
          let len = splitInner(sentence, need, sepIx + 1, need - maxLack);
          currentChunk.push(sentence.slice(0, len));
          sentence = sentence.slice(len);
        }

        chunks.push(currentChunk.join(""));
        currentChunk = [];
        currentLength = 0;
      }
      //剩余部分仍然超出，细分一下
      while (sentence.length > chunkSize) {
        const len = splitInner(sentence, chunkSize, sepIx + 1, chunkSize - maxLack);
        chunks.push(sentence.slice(0, len));
        sentence = sentence.slice(len);
      }
      currentChunk.push(sentence);
      currentLength += sentence.length;
    }

    if (currentChunk.length > 0) {
      chunks.push(currentChunk.join(""));
    }

    // 3. 添加重叠区（可选）
    //return this._addOverlap(chunks);

    //require("fs").writeFileSync("all.txt", text);
    //chunks.map((s, i) => require("fs").writeFileSync(i + "-" + s.length + ".log", s));
    return chunks;

    function splitInner(sentence, needSize, ix, minSize) {
      let curLen = 0;
      let parts = sentence.split(separators[ix] || "");
      for (const part of parts) {
        //长度已够: 已超出1000，或920至1000
        const addLen = curLen + part.length;
        if (addLen > needSize || (minSize && addLen > minSize)) {
          const leftSize = needSize - curLen;
          //末尾长度过长，需再细拆
          if (addLen > needSize) {
            var subLen = splitInner(part, leftSize, ix + 1, leftSize > maxLack ? leftSize - maxLack : 0);
            curLen += subLen;
          } else
            curLen = addLen;
          break;
        } else
          curLen += part.length;
      }
      return curLen;
    }
  }

  // _addOverlap(chunks) {
  //   return chunks.map((chunk, index) => {
  //     if (index === 0) return chunk;
  //     const prev = chunks[index - 1];
  //     const overlapText = prev.slice(-this.chunkOverlap);
  //     return overlapText + chunk;
  //   });
  // }
};
