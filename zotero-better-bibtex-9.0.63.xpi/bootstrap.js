var { install, onMainWindowLoad, onMainWindowUnload, shutdown, startup, uninstall } = (() => {
  var __create = Object.create;
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __getProtoOf = Object.getPrototypeOf;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __commonJS = (cb, mod) => function __require() {
    try {
      return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
    } catch (e) {
      throw mod = 0, e;
    }
  };
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
    // If the importer is in node compatibility mode or this is not an ESM
    // file that has been converted to a CommonJS file using a Babel-
    // compatible transform (i.e. "__esModule" has not been set), then set
    // "default" to the CommonJS "module.exports" for node compatibility.
    isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
    mod
  ));
  var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

  // node_modules/uzip/UZIP.js
  var require_UZIP = __commonJS({
    "node_modules/uzip/UZIP.js"(exports, module) {
      var UZIP = {};
      if (typeof module == "object") module.exports = UZIP;
      UZIP["parse"] = function(buf, onlyNames) {
        var rUs = UZIP.bin.readUshort, rUi = UZIP.bin.readUint, o = 0, out = {};
        var data = new Uint8Array(buf);
        var eocd = data.length - 4;
        while (rUi(data, eocd) != 101010256) eocd--;
        var o = eocd;
        o += 4;
        o += 4;
        var cnu = rUs(data, o);
        o += 2;
        var cnt = rUs(data, o);
        o += 2;
        var csize = rUi(data, o);
        o += 4;
        var coffs = rUi(data, o);
        o += 4;
        o = coffs;
        for (var i = 0; i < cnu; i++) {
          var sign = rUi(data, o);
          o += 4;
          o += 4;
          o += 4;
          o += 4;
          var crc32 = rUi(data, o);
          o += 4;
          var csize = rUi(data, o);
          o += 4;
          var usize = rUi(data, o);
          o += 4;
          var nl = rUs(data, o), el = rUs(data, o + 2), cl = rUs(data, o + 4);
          o += 6;
          o += 8;
          var roff = rUi(data, o);
          o += 4;
          o += nl + el + cl;
          UZIP._readLocal(data, roff, out, csize, usize, onlyNames);
        }
        return out;
      };
      UZIP._readLocal = function(data, o, out, csize, usize, onlyNames) {
        var rUs = UZIP.bin.readUshort, rUi = UZIP.bin.readUint;
        var sign = rUi(data, o);
        o += 4;
        var ver = rUs(data, o);
        o += 2;
        var gpflg = rUs(data, o);
        o += 2;
        var cmpr = rUs(data, o);
        o += 2;
        var time = rUi(data, o);
        o += 4;
        var crc32 = rUi(data, o);
        o += 4;
        o += 8;
        var nlen = rUs(data, o);
        o += 2;
        var elen = rUs(data, o);
        o += 2;
        var name = UZIP.bin.readUTF8(data, o, nlen);
        o += nlen;
        o += elen;
        if (onlyNames) {
          out[name] = { size: usize, csize };
          return;
        }
        var file = new Uint8Array(data.buffer, o);
        if (false) {
        } else if (cmpr == 0) out[name] = new Uint8Array(file.buffer.slice(o, o + csize));
        else if (cmpr == 8) {
          var buf = new Uint8Array(usize);
          UZIP.inflateRaw(file, buf);
          out[name] = buf;
        } else throw "unknown compression method: " + cmpr;
      };
      UZIP.inflateRaw = function(file, buf) {
        return UZIP.F.inflate(file, buf);
      };
      UZIP.inflate = function(file, buf) {
        var CMF = file[0], FLG = file[1];
        var CM = CMF & 15, CINFO = CMF >>> 4;
        return UZIP.inflateRaw(new Uint8Array(file.buffer, file.byteOffset + 2, file.length - 6), buf);
      };
      UZIP.deflate = function(data, opts) {
        if (opts == null) opts = { level: 6 };
        var off = 0, buf = new Uint8Array(50 + Math.floor(data.length * 1.1));
        buf[off] = 120;
        buf[off + 1] = 156;
        off += 2;
        off = UZIP.F.deflateRaw(data, buf, off, opts.level);
        var crc = UZIP.adler(data, 0, data.length);
        buf[off + 0] = crc >>> 24 & 255;
        buf[off + 1] = crc >>> 16 & 255;
        buf[off + 2] = crc >>> 8 & 255;
        buf[off + 3] = crc >>> 0 & 255;
        return new Uint8Array(buf.buffer, 0, off + 4);
      };
      UZIP.deflateRaw = function(data, opts) {
        if (opts == null) opts = { level: 6 };
        var buf = new Uint8Array(50 + Math.floor(data.length * 1.1));
        var off = UZIP.F.deflateRaw(data, buf, off, opts.level);
        return new Uint8Array(buf.buffer, 0, off);
      };
      UZIP.encode = function(obj, noCmpr) {
        if (noCmpr == null) noCmpr = false;
        var tot = 0, wUi = UZIP.bin.writeUint, wUs = UZIP.bin.writeUshort;
        var zpd = {};
        for (var p in obj) {
          var cpr = !UZIP._noNeed(p) && !noCmpr, buf = obj[p], crc = UZIP.crc.crc(buf, 0, buf.length);
          zpd[p] = { cpr, usize: buf.length, crc, file: cpr ? UZIP.deflateRaw(buf) : buf };
        }
        for (var p in zpd) tot += zpd[p].file.length + 30 + 46 + 2 * UZIP.bin.sizeUTF8(p);
        tot += 22;
        var data = new Uint8Array(tot), o = 0;
        var fof = [];
        for (var p in zpd) {
          var file = zpd[p];
          fof.push(o);
          o = UZIP._writeHeader(data, o, p, file, 0);
        }
        var i = 0, ioff = o;
        for (var p in zpd) {
          var file = zpd[p];
          fof.push(o);
          o = UZIP._writeHeader(data, o, p, file, 1, fof[i++]);
        }
        var csize = o - ioff;
        wUi(data, o, 101010256);
        o += 4;
        o += 4;
        wUs(data, o, i);
        o += 2;
        wUs(data, o, i);
        o += 2;
        wUi(data, o, csize);
        o += 4;
        wUi(data, o, ioff);
        o += 4;
        o += 2;
        return data.buffer;
      };
      UZIP._noNeed = function(fn) {
        var ext = fn.split(".").pop().toLowerCase();
        return "png,jpg,jpeg,zip".indexOf(ext) != -1;
      };
      UZIP._writeHeader = function(data, o, p, obj, t, roff) {
        var wUi = UZIP.bin.writeUint, wUs = UZIP.bin.writeUshort;
        var file = obj.file;
        wUi(data, o, t == 0 ? 67324752 : 33639248);
        o += 4;
        if (t == 1) o += 2;
        wUs(data, o, 20);
        o += 2;
        wUs(data, o, 0);
        o += 2;
        wUs(data, o, obj.cpr ? 8 : 0);
        o += 2;
        wUi(data, o, 0);
        o += 4;
        wUi(data, o, obj.crc);
        o += 4;
        wUi(data, o, file.length);
        o += 4;
        wUi(data, o, obj.usize);
        o += 4;
        wUs(data, o, UZIP.bin.sizeUTF8(p));
        o += 2;
        wUs(data, o, 0);
        o += 2;
        if (t == 1) {
          o += 2;
          o += 2;
          o += 6;
          wUi(data, o, roff);
          o += 4;
        }
        var nlen = UZIP.bin.writeUTF8(data, o, p);
        o += nlen;
        if (t == 0) {
          data.set(file, o);
          o += file.length;
        }
        return o;
      };
      UZIP.crc = {
        table: (function() {
          var tab = new Uint32Array(256);
          for (var n = 0; n < 256; n++) {
            var c = n;
            for (var k = 0; k < 8; k++) {
              if (c & 1) c = 3988292384 ^ c >>> 1;
              else c = c >>> 1;
            }
            tab[n] = c;
          }
          return tab;
        })(),
        update: function(c, buf, off, len) {
          for (var i = 0; i < len; i++) c = UZIP.crc.table[(c ^ buf[off + i]) & 255] ^ c >>> 8;
          return c;
        },
        crc: function(b, o, l) {
          return UZIP.crc.update(4294967295, b, o, l) ^ 4294967295;
        }
      };
      UZIP.adler = function(data, o, len) {
        var a = 1, b = 0;
        var off = o, end = o + len;
        while (off < end) {
          var eend = Math.min(off + 5552, end);
          while (off < eend) {
            a += data[off++];
            b += a;
          }
          a = a % 65521;
          b = b % 65521;
        }
        return b << 16 | a;
      };
      UZIP.bin = {
        readUshort: function(buff, p) {
          return buff[p] | buff[p + 1] << 8;
        },
        writeUshort: function(buff, p, n) {
          buff[p] = n & 255;
          buff[p + 1] = n >> 8 & 255;
        },
        readUint: function(buff, p) {
          return buff[p + 3] * (256 * 256 * 256) + (buff[p + 2] << 16 | buff[p + 1] << 8 | buff[p]);
        },
        writeUint: function(buff, p, n) {
          buff[p] = n & 255;
          buff[p + 1] = n >> 8 & 255;
          buff[p + 2] = n >> 16 & 255;
          buff[p + 3] = n >> 24 & 255;
        },
        readASCII: function(buff, p, l) {
          var s = "";
          for (var i = 0; i < l; i++) s += String.fromCharCode(buff[p + i]);
          return s;
        },
        writeASCII: function(data, p, s) {
          for (var i = 0; i < s.length; i++) data[p + i] = s.charCodeAt(i);
        },
        pad: function(n) {
          return n.length < 2 ? "0" + n : n;
        },
        readUTF8: function(buff, p, l) {
          var s = "", ns;
          for (var i = 0; i < l; i++) s += "%" + UZIP.bin.pad(buff[p + i].toString(16));
          try {
            ns = decodeURIComponent(s);
          } catch (e) {
            return UZIP.bin.readASCII(buff, p, l);
          }
          return ns;
        },
        writeUTF8: function(buff, p, str) {
          var strl = str.length, i = 0;
          for (var ci = 0; ci < strl; ci++) {
            var code = str.charCodeAt(ci);
            if ((code & 4294967295 - (1 << 7) + 1) == 0) {
              buff[p + i] = code;
              i++;
            } else if ((code & 4294967295 - (1 << 11) + 1) == 0) {
              buff[p + i] = 192 | code >> 6;
              buff[p + i + 1] = 128 | code >> 0 & 63;
              i += 2;
            } else if ((code & 4294967295 - (1 << 16) + 1) == 0) {
              buff[p + i] = 224 | code >> 12;
              buff[p + i + 1] = 128 | code >> 6 & 63;
              buff[p + i + 2] = 128 | code >> 0 & 63;
              i += 3;
            } else if ((code & 4294967295 - (1 << 21) + 1) == 0) {
              buff[p + i] = 240 | code >> 18;
              buff[p + i + 1] = 128 | code >> 12 & 63;
              buff[p + i + 2] = 128 | code >> 6 & 63;
              buff[p + i + 3] = 128 | code >> 0 & 63;
              i += 4;
            } else throw "e";
          }
          return i;
        },
        sizeUTF8: function(str) {
          var strl = str.length, i = 0;
          for (var ci = 0; ci < strl; ci++) {
            var code = str.charCodeAt(ci);
            if ((code & 4294967295 - (1 << 7) + 1) == 0) {
              i++;
            } else if ((code & 4294967295 - (1 << 11) + 1) == 0) {
              i += 2;
            } else if ((code & 4294967295 - (1 << 16) + 1) == 0) {
              i += 3;
            } else if ((code & 4294967295 - (1 << 21) + 1) == 0) {
              i += 4;
            } else throw "e";
          }
          return i;
        }
      };
      UZIP.F = {};
      UZIP.F.deflateRaw = function(data, out, opos, lvl) {
        var opts = [
          /*
          	 ush good_length; /* reduce lazy search above this match length 
          	 ush max_lazy;    /* do not perform lazy search above this match length 
                  ush nice_length; /* quit search above this match length 
          */
          /*      good lazy nice chain */
          /* 0 */
          [0, 0, 0, 0, 0],
          /* store only */
          /* 1 */
          [4, 4, 8, 4, 0],
          /* max speed, no lazy matches */
          /* 2 */
          [4, 5, 16, 8, 0],
          /* 3 */
          [4, 6, 16, 16, 0],
          /* 4 */
          [4, 10, 16, 32, 0],
          /* lazy matches */
          /* 5 */
          [8, 16, 32, 32, 0],
          /* 6 */
          [8, 16, 128, 128, 0],
          /* 7 */
          [8, 32, 128, 256, 0],
          /* 8 */
          [32, 128, 258, 1024, 1],
          /* 9 */
          [32, 258, 258, 4096, 1]
        ];
        var opt = opts[lvl];
        var U = UZIP.F.U, goodIndex = UZIP.F._goodIndex, hash = UZIP.F._hash, putsE = UZIP.F._putsE;
        var i = 0, pos = opos << 3, cvrd = 0, dlen = data.length;
        if (lvl == 0) {
          while (i < dlen) {
            var len = Math.min(65535, dlen - i);
            putsE(out, pos, i + len == dlen ? 1 : 0);
            pos = UZIP.F._copyExact(data, i, len, out, pos + 8);
            i += len;
          }
          return pos >>> 3;
        }
        var lits = U.lits, strt = U.strt, prev = U.prev, li = 0, lc = 0, bs = 0, ebits = 0, c = 0, nc = 0;
        if (dlen > 2) {
          nc = UZIP.F._hash(data, 0);
          strt[nc] = 0;
        }
        var nmch = 0, nmci = 0;
        for (i = 0; i < dlen; i++) {
          c = nc;
          if (i + 1 < dlen - 2) {
            nc = UZIP.F._hash(data, i + 1);
            var ii = i + 1 & 32767;
            prev[ii] = strt[nc];
            strt[nc] = ii;
          }
          if (cvrd <= i) {
            if ((li > 14e3 || lc > 26697) && dlen - i > 100) {
              if (cvrd < i) {
                lits[li] = i - cvrd;
                li += 2;
                cvrd = i;
              }
              pos = UZIP.F._writeBlock(i == dlen - 1 || cvrd == dlen ? 1 : 0, lits, li, ebits, data, bs, i - bs, out, pos);
              li = lc = ebits = 0;
              bs = i;
            }
            var mch = 0;
            if (i < dlen - 2) mch = UZIP.F._bestMatch(data, i, prev, c, Math.min(opt[2], dlen - i), opt[3]);
            var len = mch >>> 16, dst = mch & 65535;
            if (mch != 0) {
              var len = mch >>> 16, dst = mch & 65535;
              var lgi = goodIndex(len, U.of0);
              U.lhst[257 + lgi]++;
              var dgi = goodIndex(dst, U.df0);
              U.dhst[dgi]++;
              ebits += U.exb[lgi] + U.dxb[dgi];
              lits[li] = len << 23 | i - cvrd;
              lits[li + 1] = dst << 16 | lgi << 8 | dgi;
              li += 2;
              cvrd = i + len;
            } else {
              U.lhst[data[i]]++;
            }
            lc++;
          }
        }
        if (bs != i || data.length == 0) {
          if (cvrd < i) {
            lits[li] = i - cvrd;
            li += 2;
            cvrd = i;
          }
          pos = UZIP.F._writeBlock(1, lits, li, ebits, data, bs, i - bs, out, pos);
          li = 0;
          lc = 0;
          li = lc = ebits = 0;
          bs = i;
        }
        while ((pos & 7) != 0) pos++;
        return pos >>> 3;
      };
      UZIP.F._bestMatch = function(data, i, prev, c, nice, chain) {
        var ci = i & 32767, pi = prev[ci];
        var dif = ci - pi + (1 << 15) & 32767;
        if (pi == ci || c != UZIP.F._hash(data, i - dif)) return 0;
        var tl = 0, td = 0;
        var dlim = Math.min(32767, i);
        while (dif <= dlim && --chain != 0 && pi != ci) {
          if (tl == 0 || data[i + tl] == data[i + tl - dif]) {
            var cl = UZIP.F._howLong(data, i, dif);
            if (cl > tl) {
              tl = cl;
              td = dif;
              if (tl >= nice) break;
              if (dif + 2 < cl) cl = dif + 2;
              var maxd = 0;
              for (var j = 0; j < cl - 2; j++) {
                var ei = i - dif + j + (1 << 15) & 32767;
                var li = prev[ei];
                var curd = ei - li + (1 << 15) & 32767;
                if (curd > maxd) {
                  maxd = curd;
                  pi = ei;
                }
              }
            }
          }
          ci = pi;
          pi = prev[ci];
          dif += ci - pi + (1 << 15) & 32767;
        }
        return tl << 16 | td;
      };
      UZIP.F._howLong = function(data, i, dif) {
        if (data[i] != data[i - dif] || data[i + 1] != data[i + 1 - dif] || data[i + 2] != data[i + 2 - dif]) return 0;
        var oi = i, l = Math.min(data.length, i + 258);
        i += 3;
        while (i < l && data[i] == data[i - dif]) i++;
        return i - oi;
      };
      UZIP.F._hash = function(data, i) {
        return (data[i] << 8 | data[i + 1]) + (data[i + 2] << 4) & 65535;
      };
      UZIP.saved = 0;
      UZIP.F._writeBlock = function(BFINAL, lits, li, ebits, data, o0, l0, out, pos) {
        var U = UZIP.F.U, putsF = UZIP.F._putsF, putsE = UZIP.F._putsE;
        var T, ML, MD, MH, numl, numd, numh, lset, dset;
        U.lhst[256]++;
        T = UZIP.F.getTrees();
        ML = T[0];
        MD = T[1];
        MH = T[2];
        numl = T[3];
        numd = T[4];
        numh = T[5];
        lset = T[6];
        dset = T[7];
        var cstSize = ((pos + 3 & 7) == 0 ? 0 : 8 - (pos + 3 & 7)) + 32 + (l0 << 3);
        var fxdSize = ebits + UZIP.F.contSize(U.fltree, U.lhst) + UZIP.F.contSize(U.fdtree, U.dhst);
        var dynSize = ebits + UZIP.F.contSize(U.ltree, U.lhst) + UZIP.F.contSize(U.dtree, U.dhst);
        dynSize += 14 + 3 * numh + UZIP.F.contSize(U.itree, U.ihst) + (U.ihst[16] * 2 + U.ihst[17] * 3 + U.ihst[18] * 7);
        for (var j = 0; j < 286; j++) U.lhst[j] = 0;
        for (var j = 0; j < 30; j++) U.dhst[j] = 0;
        for (var j = 0; j < 19; j++) U.ihst[j] = 0;
        var BTYPE = cstSize < fxdSize && cstSize < dynSize ? 0 : fxdSize < dynSize ? 1 : 2;
        putsF(out, pos, BFINAL);
        putsF(out, pos + 1, BTYPE);
        pos += 3;
        var opos = pos;
        if (BTYPE == 0) {
          while ((pos & 7) != 0) pos++;
          pos = UZIP.F._copyExact(data, o0, l0, out, pos);
        } else {
          var ltree, dtree;
          if (BTYPE == 1) {
            ltree = U.fltree;
            dtree = U.fdtree;
          }
          if (BTYPE == 2) {
            UZIP.F.makeCodes(U.ltree, ML);
            UZIP.F.revCodes(U.ltree, ML);
            UZIP.F.makeCodes(U.dtree, MD);
            UZIP.F.revCodes(U.dtree, MD);
            UZIP.F.makeCodes(U.itree, MH);
            UZIP.F.revCodes(U.itree, MH);
            ltree = U.ltree;
            dtree = U.dtree;
            putsE(out, pos, numl - 257);
            pos += 5;
            putsE(out, pos, numd - 1);
            pos += 5;
            putsE(out, pos, numh - 4);
            pos += 4;
            for (var i = 0; i < numh; i++) putsE(out, pos + i * 3, U.itree[(U.ordr[i] << 1) + 1]);
            pos += 3 * numh;
            pos = UZIP.F._codeTiny(lset, U.itree, out, pos);
            pos = UZIP.F._codeTiny(dset, U.itree, out, pos);
          }
          var off = o0;
          for (var si = 0; si < li; si += 2) {
            var qb = lits[si], len = qb >>> 23, end = off + (qb & (1 << 23) - 1);
            while (off < end) pos = UZIP.F._writeLit(data[off++], ltree, out, pos);
            if (len != 0) {
              var qc = lits[si + 1], dst = qc >> 16, lgi = qc >> 8 & 255, dgi = qc & 255;
              pos = UZIP.F._writeLit(257 + lgi, ltree, out, pos);
              putsE(out, pos, len - U.of0[lgi]);
              pos += U.exb[lgi];
              pos = UZIP.F._writeLit(dgi, dtree, out, pos);
              putsF(out, pos, dst - U.df0[dgi]);
              pos += U.dxb[dgi];
              off += len;
            }
          }
          pos = UZIP.F._writeLit(256, ltree, out, pos);
        }
        return pos;
      };
      UZIP.F._copyExact = function(data, off, len, out, pos) {
        var p8 = pos >>> 3;
        out[p8] = len;
        out[p8 + 1] = len >>> 8;
        out[p8 + 2] = 255 - out[p8];
        out[p8 + 3] = 255 - out[p8 + 1];
        p8 += 4;
        out.set(new Uint8Array(data.buffer, off, len), p8);
        return pos + (len + 4 << 3);
      };
      UZIP.F.getTrees = function() {
        var U = UZIP.F.U;
        var ML = UZIP.F._hufTree(U.lhst, U.ltree, 15);
        var MD = UZIP.F._hufTree(U.dhst, U.dtree, 15);
        var lset = [], numl = UZIP.F._lenCodes(U.ltree, lset);
        var dset = [], numd = UZIP.F._lenCodes(U.dtree, dset);
        for (var i = 0; i < lset.length; i += 2) U.ihst[lset[i]]++;
        for (var i = 0; i < dset.length; i += 2) U.ihst[dset[i]]++;
        var MH = UZIP.F._hufTree(U.ihst, U.itree, 7);
        var numh = 19;
        while (numh > 4 && U.itree[(U.ordr[numh - 1] << 1) + 1] == 0) numh--;
        return [ML, MD, MH, numl, numd, numh, lset, dset];
      };
      UZIP.F.getSecond = function(a) {
        var b = [];
        for (var i = 0; i < a.length; i += 2) b.push(a[i + 1]);
        return b;
      };
      UZIP.F.nonZero = function(a) {
        var b = "";
        for (var i = 0; i < a.length; i += 2) if (a[i + 1] != 0) b += (i >> 1) + ",";
        return b;
      };
      UZIP.F.contSize = function(tree, hst) {
        var s = 0;
        for (var i = 0; i < hst.length; i++) s += hst[i] * tree[(i << 1) + 1];
        return s;
      };
      UZIP.F._codeTiny = function(set, tree, out, pos) {
        for (var i = 0; i < set.length; i += 2) {
          var l = set[i], rst = set[i + 1];
          pos = UZIP.F._writeLit(l, tree, out, pos);
          var rsl = l == 16 ? 2 : l == 17 ? 3 : 7;
          if (l > 15) {
            UZIP.F._putsE(out, pos, rst, rsl);
            pos += rsl;
          }
        }
        return pos;
      };
      UZIP.F._lenCodes = function(tree, set) {
        var len = tree.length;
        while (len != 2 && tree[len - 1] == 0) len -= 2;
        for (var i = 0; i < len; i += 2) {
          var l = tree[i + 1], nxt = i + 3 < len ? tree[i + 3] : -1, nnxt = i + 5 < len ? tree[i + 5] : -1, prv = i == 0 ? -1 : tree[i - 1];
          if (l == 0 && nxt == l && nnxt == l) {
            var lz = i + 5;
            while (lz + 2 < len && tree[lz + 2] == l) lz += 2;
            var zc = Math.min(lz + 1 - i >>> 1, 138);
            if (zc < 11) set.push(17, zc - 3);
            else set.push(18, zc - 11);
            i += zc * 2 - 2;
          } else if (l == prv && nxt == l && nnxt == l) {
            var lz = i + 5;
            while (lz + 2 < len && tree[lz + 2] == l) lz += 2;
            var zc = Math.min(lz + 1 - i >>> 1, 6);
            set.push(16, zc - 3);
            i += zc * 2 - 2;
          } else set.push(l, 0);
        }
        return len >>> 1;
      };
      UZIP.F._hufTree = function(hst, tree, MAXL) {
        var list = [], hl = hst.length, tl = tree.length, i = 0;
        for (i = 0; i < tl; i += 2) {
          tree[i] = 0;
          tree[i + 1] = 0;
        }
        for (i = 0; i < hl; i++) if (hst[i] != 0) list.push({ lit: i, f: hst[i] });
        var end = list.length, l2 = list.slice(0);
        if (end == 0) return 0;
        if (end == 1) {
          var lit = list[0].lit, l2 = lit == 0 ? 1 : 0;
          tree[(lit << 1) + 1] = 1;
          tree[(l2 << 1) + 1] = 1;
          return 1;
        }
        list.sort(function(a2, b2) {
          return a2.f - b2.f;
        });
        var a = list[0], b = list[1], i0 = 0, i1 = 1, i2 = 2;
        list[0] = { lit: -1, f: a.f + b.f, l: a, r: b, d: 0 };
        while (i1 != end - 1) {
          if (i0 != i1 && (i2 == end || list[i0].f < list[i2].f)) {
            a = list[i0++];
          } else {
            a = list[i2++];
          }
          if (i0 != i1 && (i2 == end || list[i0].f < list[i2].f)) {
            b = list[i0++];
          } else {
            b = list[i2++];
          }
          list[i1++] = { lit: -1, f: a.f + b.f, l: a, r: b };
        }
        var maxl = UZIP.F.setDepth(list[i1 - 1], 0);
        if (maxl > MAXL) {
          UZIP.F.restrictDepth(l2, MAXL, maxl);
          maxl = MAXL;
        }
        for (i = 0; i < end; i++) tree[(l2[i].lit << 1) + 1] = l2[i].d;
        return maxl;
      };
      UZIP.F.setDepth = function(t, d) {
        if (t.lit != -1) {
          t.d = d;
          return d;
        }
        return Math.max(UZIP.F.setDepth(t.l, d + 1), UZIP.F.setDepth(t.r, d + 1));
      };
      UZIP.F.restrictDepth = function(dps, MD, maxl) {
        var i = 0, bCost = 1 << maxl - MD, dbt = 0;
        dps.sort(function(a, b) {
          return b.d == a.d ? a.f - b.f : b.d - a.d;
        });
        for (i = 0; i < dps.length; i++) if (dps[i].d > MD) {
          var od = dps[i].d;
          dps[i].d = MD;
          dbt += bCost - (1 << maxl - od);
        } else break;
        dbt = dbt >>> maxl - MD;
        while (dbt > 0) {
          var od = dps[i].d;
          if (od < MD) {
            dps[i].d++;
            dbt -= 1 << MD - od - 1;
          } else i++;
        }
        for (; i >= 0; i--) if (dps[i].d == MD && dbt < 0) {
          dps[i].d--;
          dbt++;
        }
        if (dbt != 0) ;
      };
      UZIP.F._goodIndex = function(v, arr) {
        var i = 0;
        if (arr[i | 16] <= v) i |= 16;
        if (arr[i | 8] <= v) i |= 8;
        if (arr[i | 4] <= v) i |= 4;
        if (arr[i | 2] <= v) i |= 2;
        if (arr[i | 1] <= v) i |= 1;
        return i;
      };
      UZIP.F._writeLit = function(ch, ltree, out, pos) {
        UZIP.F._putsF(out, pos, ltree[ch << 1]);
        return pos + ltree[(ch << 1) + 1];
      };
      UZIP.F.inflate = function(data, buf) {
        var u8 = Uint8Array;
        if (data[0] == 3 && data[1] == 0) return buf ? buf : new u8(0);
        var F = UZIP.F, bitsF = F._bitsF, bitsE = F._bitsE, decodeTiny = F._decodeTiny, makeCodes = F.makeCodes, codes2map = F.codes2map, get17 = F._get17;
        var U = F.U;
        var noBuf = buf == null;
        if (noBuf) buf = new u8(data.length >>> 2 << 3);
        var BFINAL = 0, BTYPE = 0, HLIT = 0, HDIST = 0, HCLEN = 0, ML = 0, MD = 0;
        var off = 0, pos = 0;
        var lmap, dmap;
        while (BFINAL == 0) {
          BFINAL = bitsF(data, pos, 1);
          BTYPE = bitsF(data, pos + 1, 2);
          pos += 3;
          if (BTYPE == 0) {
            if ((pos & 7) != 0) pos += 8 - (pos & 7);
            var p8 = (pos >>> 3) + 4, len = data[p8 - 4] | data[p8 - 3] << 8;
            if (noBuf) buf = UZIP.F._check(buf, off + len);
            buf.set(new u8(data.buffer, data.byteOffset + p8, len), off);
            pos = p8 + len << 3;
            off += len;
            continue;
          }
          if (noBuf) buf = UZIP.F._check(buf, off + (1 << 17));
          if (BTYPE == 1) {
            lmap = U.flmap;
            dmap = U.fdmap;
            ML = (1 << 9) - 1;
            MD = (1 << 5) - 1;
          }
          if (BTYPE == 2) {
            HLIT = bitsE(data, pos, 5) + 257;
            HDIST = bitsE(data, pos + 5, 5) + 1;
            HCLEN = bitsE(data, pos + 10, 4) + 4;
            pos += 14;
            var ppos = pos;
            for (var i = 0; i < 38; i += 2) {
              U.itree[i] = 0;
              U.itree[i + 1] = 0;
            }
            var tl = 1;
            for (var i = 0; i < HCLEN; i++) {
              var l = bitsE(data, pos + i * 3, 3);
              U.itree[(U.ordr[i] << 1) + 1] = l;
              if (l > tl) tl = l;
            }
            pos += 3 * HCLEN;
            makeCodes(U.itree, tl);
            codes2map(U.itree, tl, U.imap);
            lmap = U.lmap;
            dmap = U.dmap;
            pos = decodeTiny(U.imap, (1 << tl) - 1, HLIT + HDIST, data, pos, U.ttree);
            var mx0 = F._copyOut(U.ttree, 0, HLIT, U.ltree);
            ML = (1 << mx0) - 1;
            var mx1 = F._copyOut(U.ttree, HLIT, HDIST, U.dtree);
            MD = (1 << mx1) - 1;
            makeCodes(U.ltree, mx0);
            codes2map(U.ltree, mx0, lmap);
            makeCodes(U.dtree, mx1);
            codes2map(U.dtree, mx1, dmap);
          }
          while (true) {
            var code = lmap[get17(data, pos) & ML];
            pos += code & 15;
            var lit = code >>> 4;
            if (lit >>> 8 == 0) {
              buf[off++] = lit;
            } else if (lit == 256) {
              break;
            } else {
              var end = off + lit - 254;
              if (lit > 264) {
                var ebs = U.ldef[lit - 257];
                end = off + (ebs >>> 3) + bitsE(data, pos, ebs & 7);
                pos += ebs & 7;
              }
              var dcode = dmap[get17(data, pos) & MD];
              pos += dcode & 15;
              var dlit = dcode >>> 4;
              var dbs = U.ddef[dlit], dst = (dbs >>> 4) + bitsF(data, pos, dbs & 15);
              pos += dbs & 15;
              if (noBuf) buf = UZIP.F._check(buf, off + (1 << 17));
              while (off < end) {
                buf[off] = buf[off++ - dst];
                buf[off] = buf[off++ - dst];
                buf[off] = buf[off++ - dst];
                buf[off] = buf[off++ - dst];
              }
              off = end;
            }
          }
        }
        return buf.length == off ? buf : buf.slice(0, off);
      };
      UZIP.F._check = function(buf, len) {
        var bl = buf.length;
        if (len <= bl) return buf;
        var nbuf = new Uint8Array(Math.max(bl << 1, len));
        nbuf.set(buf, 0);
        return nbuf;
      };
      UZIP.F._decodeTiny = function(lmap, LL, len, data, pos, tree) {
        var bitsE = UZIP.F._bitsE, get17 = UZIP.F._get17;
        var i = 0;
        while (i < len) {
          var code = lmap[get17(data, pos) & LL];
          pos += code & 15;
          var lit = code >>> 4;
          if (lit <= 15) {
            tree[i] = lit;
            i++;
          } else {
            var ll = 0, n = 0;
            if (lit == 16) {
              n = 3 + bitsE(data, pos, 2);
              pos += 2;
              ll = tree[i - 1];
            } else if (lit == 17) {
              n = 3 + bitsE(data, pos, 3);
              pos += 3;
            } else if (lit == 18) {
              n = 11 + bitsE(data, pos, 7);
              pos += 7;
            }
            var ni = i + n;
            while (i < ni) {
              tree[i] = ll;
              i++;
            }
          }
        }
        return pos;
      };
      UZIP.F._copyOut = function(src, off, len, tree) {
        var mx = 0, i = 0, tl = tree.length >>> 1;
        while (i < len) {
          var v = src[i + off];
          tree[i << 1] = 0;
          tree[(i << 1) + 1] = v;
          if (v > mx) mx = v;
          i++;
        }
        while (i < tl) {
          tree[i << 1] = 0;
          tree[(i << 1) + 1] = 0;
          i++;
        }
        return mx;
      };
      UZIP.F.makeCodes = function(tree, MAX_BITS) {
        var U = UZIP.F.U;
        var max_code = tree.length;
        var code, bits, n, i, len;
        var bl_count = U.bl_count;
        for (var i = 0; i <= MAX_BITS; i++) bl_count[i] = 0;
        for (i = 1; i < max_code; i += 2) bl_count[tree[i]]++;
        var next_code = U.next_code;
        code = 0;
        bl_count[0] = 0;
        for (bits = 1; bits <= MAX_BITS; bits++) {
          code = code + bl_count[bits - 1] << 1;
          next_code[bits] = code;
        }
        for (n = 0; n < max_code; n += 2) {
          len = tree[n + 1];
          if (len != 0) {
            tree[n] = next_code[len];
            next_code[len]++;
          }
        }
      };
      UZIP.F.codes2map = function(tree, MAX_BITS, map) {
        var max_code = tree.length;
        var U = UZIP.F.U, r15 = U.rev15;
        for (var i = 0; i < max_code; i += 2) if (tree[i + 1] != 0) {
          var lit = i >> 1;
          var cl = tree[i + 1], val = lit << 4 | cl;
          var rest = MAX_BITS - cl, i0 = tree[i] << rest, i1 = i0 + (1 << rest);
          while (i0 != i1) {
            var p0 = r15[i0] >>> 15 - MAX_BITS;
            map[p0] = val;
            i0++;
          }
        }
      };
      UZIP.F.revCodes = function(tree, MAX_BITS) {
        var r15 = UZIP.F.U.rev15, imb = 15 - MAX_BITS;
        for (var i = 0; i < tree.length; i += 2) {
          var i0 = tree[i] << MAX_BITS - tree[i + 1];
          tree[i] = r15[i0] >>> imb;
        }
      };
      UZIP.F._putsE = function(dt, pos, val) {
        val = val << (pos & 7);
        var o = pos >>> 3;
        dt[o] |= val;
        dt[o + 1] |= val >>> 8;
      };
      UZIP.F._putsF = function(dt, pos, val) {
        val = val << (pos & 7);
        var o = pos >>> 3;
        dt[o] |= val;
        dt[o + 1] |= val >>> 8;
        dt[o + 2] |= val >>> 16;
      };
      UZIP.F._bitsE = function(dt, pos, length) {
        return (dt[pos >>> 3] | dt[(pos >>> 3) + 1] << 8) >>> (pos & 7) & (1 << length) - 1;
      };
      UZIP.F._bitsF = function(dt, pos, length) {
        return (dt[pos >>> 3] | dt[(pos >>> 3) + 1] << 8 | dt[(pos >>> 3) + 2] << 16) >>> (pos & 7) & (1 << length) - 1;
      };
      UZIP.F._get17 = function(dt, pos) {
        return (dt[pos >>> 3] | dt[(pos >>> 3) + 1] << 8 | dt[(pos >>> 3) + 2] << 16) >>> (pos & 7);
      };
      UZIP.F._get25 = function(dt, pos) {
        return (dt[pos >>> 3] | dt[(pos >>> 3) + 1] << 8 | dt[(pos >>> 3) + 2] << 16 | dt[(pos >>> 3) + 3] << 24) >>> (pos & 7);
      };
      UZIP.F.U = (function() {
        var u16 = Uint16Array, u32 = Uint32Array;
        return {
          next_code: new u16(16),
          bl_count: new u16(16),
          ordr: [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15],
          of0: [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258, 999, 999, 999],
          exb: [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0, 0, 0, 0],
          ldef: new u16(32),
          df0: [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577, 65535, 65535],
          dxb: [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 0, 0],
          ddef: new u32(32),
          flmap: new u16(512),
          fltree: [],
          fdmap: new u16(32),
          fdtree: [],
          lmap: new u16(32768),
          ltree: [],
          ttree: [],
          dmap: new u16(32768),
          dtree: [],
          imap: new u16(512),
          itree: [],
          //rev9 : new u16(  512)
          rev15: new u16(1 << 15),
          lhst: new u32(286),
          dhst: new u32(30),
          ihst: new u32(19),
          lits: new u32(15e3),
          strt: new u16(1 << 16),
          prev: new u16(1 << 15)
        };
      })();
      (function() {
        var U = UZIP.F.U;
        var len = 1 << 15;
        for (var i = 0; i < len; i++) {
          var x = i;
          x = (x & 2863311530) >>> 1 | (x & 1431655765) << 1;
          x = (x & 3435973836) >>> 2 | (x & 858993459) << 2;
          x = (x & 4042322160) >>> 4 | (x & 252645135) << 4;
          x = (x & 4278255360) >>> 8 | (x & 16711935) << 8;
          U.rev15[i] = (x >>> 16 | x << 16) >>> 17;
        }
        function pushV(tgt, n, sv) {
          while (n-- != 0) tgt.push(0, sv);
        }
        for (var i = 0; i < 32; i++) {
          U.ldef[i] = U.of0[i] << 3 | U.exb[i];
          U.ddef[i] = U.df0[i] << 4 | U.dxb[i];
        }
        pushV(U.fltree, 144, 8);
        pushV(U.fltree, 255 - 143, 9);
        pushV(U.fltree, 279 - 255, 7);
        pushV(U.fltree, 287 - 279, 8);
        UZIP.F.makeCodes(U.fltree, 9);
        UZIP.F.codes2map(U.fltree, 9, U.flmap);
        UZIP.F.revCodes(U.fltree, 9);
        pushV(U.fdtree, 32, 5);
        UZIP.F.makeCodes(U.fdtree, 5);
        UZIP.F.codes2map(U.fdtree, 5, U.fdmap);
        UZIP.F.revCodes(U.fdtree, 5);
        pushV(U.itree, 19, 0);
        pushV(U.ltree, 286, 0);
        pushV(U.dtree, 30, 0);
        pushV(U.ttree, 320, 0);
      })();
    }
  });

  // content/bootstrap.ts
  var bootstrap_exports = {};
  __export(bootstrap_exports, {
    install: () => install,
    onMainWindowLoad: () => onMainWindowLoad,
    onMainWindowUnload: () => onMainWindowUnload,
    shutdown: () => shutdown,
    startup: () => startup,
    uninstall: () => uninstall
  });

  // content/prompt.ts
  function alert({ title, text }) {
    Services.prompt.alert(null, title || "Alert", text);
  }
  function confirm({ title, text }) {
    return Services.prompt.confirm(null, title, text);
  }

  // content/public.ts
  var jwk = {
    "key_ops": [
      "encrypt"
    ],
    "ext": true,
    "alg": "RSA-OAEP-256",
    "kty": "RSA",
    "n": "35xpFMoOmVxAe94N6OeQVUX2K9WQEyo2ga0xLs7F5v_U4hupEAsDxZDKvFTHVapm-9Ips_syGr7r7gIiBWDWBJk3rmdP64_HXsBf7rJBJUcu7kZTIuLpOlF4gh7NITSGOKHT8izxunk_ga208p6tSwOrACjX0zaUdxtBgKLbjNlIs7rffDDG0p6i8aLY_sNJ7gewRgL040HRivZxcDqV79RnOcbe78sLCUW3Xgbqo144hWTBi8Jq0AyST-KWg5p2-nqjlHXqR-ep9ugOUaTKER5KN2i-0fZwsighI5j6l_R529O_vDPgrvsV2YlQQNpOllRgN2mC9YrENDQ2zGIraw",
    "e": "AQAB"
  };

  // node_modules/jose/dist/webapi/lib/buffer_utils.js
  var encoder = new TextEncoder();
  var decoder = new TextDecoder();
  var strictDecoder = new TextDecoder("utf-8", { fatal: true });
  var MAX_INT32 = 2 ** 32;
  function concat(...buffers) {
    const size = buffers.reduce((acc, { length }) => acc + length, 0);
    const buf = new Uint8Array(size);
    let i = 0;
    for (const buffer of buffers) {
      buf.set(buffer, i);
      i += buffer.length;
    }
    return buf;
  }
  function writeUInt32BE(buf, value, offset) {
    if (value < 0 || value >= MAX_INT32) {
      throw new RangeError(`value must be >= 0 and <= ${MAX_INT32 - 1}. Received ${value}`);
    }
    buf.set([value >>> 24, value >>> 16, value >>> 8, value & 255], offset);
  }
  function uint64be(value) {
    const high = Math.floor(value / MAX_INT32);
    const low = value % MAX_INT32;
    const buf = new Uint8Array(8);
    writeUInt32BE(buf, high, 0);
    writeUInt32BE(buf, low, 4);
    return buf;
  }
  function uint32be(value) {
    const buf = new Uint8Array(4);
    writeUInt32BE(buf, value);
    return buf;
  }
  function encode(string) {
    const bytes = new Uint8Array(string.length);
    for (let i = 0; i < string.length; i++) {
      const code = string.charCodeAt(i);
      if (code > 127) {
        throw new TypeError("non-ASCII string encountered in encode()");
      }
      bytes[i] = code;
    }
    return bytes;
  }

  // node_modules/jose/dist/webapi/lib/crypto_key.js
  var unusable = (name, prop = "algorithm.name") => new TypeError(`CryptoKey does not support this operation, its ${prop} must be ${name}`);
  function checkUsage(key, usage) {
    if (usage && !key.usages.includes(usage)) {
      throw new TypeError(`CryptoKey does not support this operation, its usages must include ${usage}.`);
    }
  }
  function checkModulusLength(alg, key) {
    const { modulusLength } = key.algorithm;
    if (typeof modulusLength !== "number" || modulusLength < 2048) {
      throw new TypeError(`${alg} requires key modulusLength to be 2048 bits or larger`);
    }
  }
  function checkCryptoKey(key, expected, usage) {
    const algorithm = key.algorithm;
    if (algorithm.name !== expected.name) {
      throw unusable(expected.name);
    }
    if (expected.hash && algorithm.hash?.name !== expected.hash) {
      throw unusable(expected.hash, "algorithm.hash");
    }
    if (expected.namedCurve && algorithm.namedCurve !== expected.namedCurve) {
      throw unusable(expected.namedCurve, "algorithm.namedCurve");
    }
    if (expected.length !== void 0 && algorithm.length !== expected.length) {
      throw unusable(expected.length, "algorithm.length");
    }
    checkUsage(key, usage);
  }

  // node_modules/jose/dist/webapi/lib/invalid_key_input.js
  function message(msg, actual, ...types) {
    if (types.length > 2) {
      const last = types.pop();
      msg += `one of type ${types.join(", ")}, or ${last}.`;
    } else if (types.length === 2) {
      msg += `one of type ${types[0]} or ${types[1]}.`;
    } else {
      msg += `of type ${types[0]}.`;
    }
    if (actual == null) {
      msg += ` Received ${actual}`;
    } else if (typeof actual === "function" && actual.name) {
      msg += ` Received function ${actual.name}`;
    } else if (typeof actual === "object" && actual != null) {
      if (actual.constructor?.name) {
        msg += ` Received an instance of ${actual.constructor.name}`;
      }
    }
    return msg;
  }
  var invalidKeyInput = (actual, ...types) => message("Key must be ", actual, ...types);
  var withAlg = (alg, actual, ...types) => message(`Key for the ${alg} algorithm must be `, actual, ...types);

  // node_modules/jose/dist/webapi/util/errors.js
  var JOSEError = class extends Error {
    static code = "ERR_JOSE_GENERIC";
    code = "ERR_JOSE_GENERIC";
    constructor(message2, options) {
      super(message2, options);
      this.name = this.constructor.name;
      Error.captureStackTrace?.(this, this.constructor);
    }
  };
  var JOSENotSupported = class extends JOSEError {
    static code = "ERR_JOSE_NOT_SUPPORTED";
    code = "ERR_JOSE_NOT_SUPPORTED";
  };
  var JWEInvalid = class extends JOSEError {
    static code = "ERR_JWE_INVALID";
    code = "ERR_JWE_INVALID";
  };

  // node_modules/jose/dist/webapi/lib/is_key_like.js
  function assertCryptoKey(key) {
    if (!isCryptoKey(key)) {
      throw new Error("CryptoKey instance expected");
    }
  }
  var isCryptoKey = (key) => {
    if (key?.[Symbol.toStringTag] === "CryptoKey")
      return true;
    try {
      return key instanceof CryptoKey;
    } catch {
      return false;
    }
  };
  var isKeyObject = (key) => key?.[Symbol.toStringTag] === "KeyObject";
  var isKeyLike = (key) => isCryptoKey(key) || isKeyObject(key);

  // node_modules/jose/dist/webapi/lib/content_encryption.js
  var generateCek = (enc) => crypto.getRandomValues(new Uint8Array(enc.cekBits >> 3));
  function checkCekLength(cek, expected) {
    const actual = cek.byteLength << 3;
    if (actual !== expected) {
      throw new JWEInvalid(`Invalid Content Encryption Key length. Expected ${expected} bits, got ${actual} bits`);
    }
  }
  var generateIv = (enc) => crypto.getRandomValues(new Uint8Array(enc.ivBits >> 3));
  function checkIvLength(enc, iv) {
    if (iv.length << 3 !== enc.ivBits) {
      throw new JWEInvalid("Invalid Initialization Vector length");
    }
  }
  async function cbcKeySetup(enc, cek, usage) {
    if (!(cek instanceof Uint8Array)) {
      throw new TypeError(invalidKeyInput(cek, "Uint8Array"));
    }
    const keySize = enc.cekBits >> 1;
    const encKey = await crypto.subtle.importKey("raw", cek.subarray(keySize >> 3), "AES-CBC", false, [usage]);
    const macKey = await crypto.subtle.importKey("raw", cek.subarray(0, keySize >> 3), {
      hash: `SHA-${keySize << 1}`,
      name: "HMAC"
    }, false, ["sign"]);
    return [encKey, macKey, keySize];
  }
  async function cbcHmacTag(macKey, macData, keySize) {
    return new Uint8Array((await crypto.subtle.sign("HMAC", macKey, macData)).slice(0, keySize >> 3));
  }
  async function cbcEncrypt(enc, plaintext, cek, iv, aad) {
    const [encKey, macKey, keySize] = await cbcKeySetup(enc, cek, "encrypt");
    const ciphertext = new Uint8Array(await crypto.subtle.encrypt({
      iv,
      name: "AES-CBC"
    }, encKey, plaintext));
    const macData = concat(aad, iv, ciphertext, uint64be(aad.length * 8));
    const tag2 = await cbcHmacTag(macKey, macData, keySize);
    return { ciphertext, tag: tag2, iv };
  }
  async function gcmEncrypt(enc, plaintext, cek, iv, aad) {
    const encKey = cek instanceof Uint8Array ? await crypto.subtle.importKey("raw", cek, "AES-GCM", false, [
      "encrypt"
    ]) : (checkCryptoKey(cek, enc.subtle, "encrypt"), cek);
    const encrypted = new Uint8Array(await crypto.subtle.encrypt({
      additionalData: aad,
      iv,
      name: "AES-GCM",
      tagLength: 128
    }, encKey, plaintext));
    const tag2 = encrypted.slice(-16);
    const ciphertext = encrypted.slice(0, -16);
    return { ciphertext, tag: tag2, iv };
  }
  async function encrypt(enc, plaintext, cek, iv, aad) {
    if (!isCryptoKey(cek) && !(cek instanceof Uint8Array)) {
      throw new TypeError(invalidKeyInput(cek, "CryptoKey", "KeyObject", "Uint8Array", "JSON Web Key"));
    }
    if (iv) {
      checkIvLength(enc, iv);
    } else {
      iv = generateIv(enc);
    }
    if (cek instanceof Uint8Array) {
      checkCekLength(cek, enc.cekBits);
    }
    return enc.cbc ? cbcEncrypt(enc, plaintext, cek, iv, aad) : gcmEncrypt(enc, plaintext, cek, iv, aad);
  }

  // node_modules/jose/dist/webapi/lib/base64.js
  function encodeBase64(input) {
    if (Uint8Array.prototype.toBase64) {
      return input.toBase64();
    }
    const CHUNK_SIZE = 32768;
    const arr = [];
    for (let i = 0; i < input.length; i += CHUNK_SIZE) {
      arr.push(String.fromCharCode.apply(null, input.subarray(i, i + CHUNK_SIZE)));
    }
    return btoa(arr.join(""));
  }
  function decodeBase64(encoded) {
    if (Uint8Array.fromBase64) {
      return Uint8Array.fromBase64(encoded);
    }
    const binary = atob(encoded);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes;
  }

  // node_modules/jose/dist/webapi/util/base64url.js
  var invalid = "The input to be decoded is not correctly encoded.";
  function decode(input) {
    if (Uint8Array.fromBase64) {
      try {
        return Uint8Array.fromBase64(typeof input === "string" ? input : decoder.decode(input), {
          alphabet: "base64url"
        });
      } catch (cause) {
        throw new TypeError(invalid, { cause });
      }
    }
    let encoded = input;
    if (encoded instanceof Uint8Array) {
      encoded = decoder.decode(encoded);
    }
    if (encoded.includes("+") || encoded.includes("/")) {
      throw new TypeError(invalid);
    }
    encoded = encoded.replace(/-/g, "+").replace(/_/g, "/");
    try {
      return decodeBase64(encoded);
    } catch {
      throw new TypeError(invalid);
    }
  }
  function encode2(input) {
    let unencoded = input;
    if (typeof unencoded === "string") {
      unencoded = encoder.encode(unencoded);
    }
    if (Uint8Array.prototype.toBase64) {
      return unencoded.toBase64({ alphabet: "base64url", omitPadding: true });
    }
    return encodeBase64(unencoded).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  }

  // node_modules/jose/dist/webapi/lib/type_checks.js
  function assertUint8Array(input, label) {
    if (!(input instanceof Uint8Array)) {
      throw new TypeError(`${label} must be an instance of Uint8Array`);
    }
  }
  function isObject(input) {
    if (typeof input !== "object" || input === null || Object.prototype.toString.call(input) !== "[object Object]") {
      return false;
    }
    const prototype = Object.getPrototypeOf(input);
    return prototype === null || Object.getPrototypeOf(prototype) === null;
  }
  function isDisjoint(...headers) {
    const parameters = /* @__PURE__ */ new Set();
    for (const header of headers) {
      if (!header)
        continue;
      for (const parameter of Object.keys(header)) {
        if (parameters.has(parameter)) {
          return false;
        }
        parameters.add(parameter);
      }
    }
    return true;
  }

  // node_modules/jose/dist/webapi/lib/helpers.js
  var unprotected = /* @__PURE__ */ Symbol();
  function assertNotSet(value, name) {
    if (value !== void 0) {
      throw new TypeError(`${name} can only be called once`);
    }
  }
  async function digest(algorithm, data) {
    const subtleDigest = `SHA-${algorithm.slice(-3)}`;
    return new Uint8Array(await crypto.subtle.digest(subtleDigest, data));
  }

  // node_modules/jose/dist/webapi/lib/jwk_to_key.js
  async function jwkToKey(entry, jwk2) {
    if (jwk2.kty === "RSA" && "oth" in jwk2 && jwk2.oth !== void 0) {
      throw new JOSENotSupported('RSA JWK "oth" (Other Primes Info) Parameter value is not supported');
    }
    if (!entry.kty.includes(jwk2.kty)) {
      throw new JOSENotSupported('Invalid or unsupported JWK "alg" (Algorithm) Parameter value');
    }
    const algorithm = entry.resolve?.({ kty: jwk2.kty, crv: jwk2.crv }) ?? entry.subtle;
    const isPrivate = !!(jwk2.d || jwk2.priv);
    const keyData = { ...jwk2 };
    if (keyData.kty !== "AKP") {
      delete keyData.alg;
    }
    delete keyData.use;
    return crypto.subtle.importKey("jwk", keyData, algorithm, jwk2.ext ?? !isPrivate, jwk2.key_ops ?? entry.usages[isPrivate ? 1 : 0]);
  }

  // node_modules/jose/dist/webapi/lib/jwk_metadata.js
  function snapshotJwk(jwk2) {
    return { __proto__: null, ...jwk2 };
  }
  function normalizeJwk(jwk2) {
    const normalized = snapshotJwk(jwk2);
    if (normalized.ext !== void 0 && typeof normalized.ext !== "boolean") {
      throw new TypeError('"ext" (Extractable) Parameter must be a boolean');
    }
    if (normalized.key_ops !== void 0) {
      const value = normalized.key_ops;
      const keyOps = Array.isArray(value) ? [...value] : void 0;
      if (!keyOps || keyOps.some((operation) => typeof operation !== "string") || new Set(keyOps).size !== keyOps.length) {
        throw new TypeError('"key_ops" (Key Operations) Parameter must be an array of unique strings');
      }
      normalized.key_ops = keyOps;
    }
    return normalized;
  }

  // node_modules/jose/dist/webapi/lib/key.js
  var tag = (key) => key[Symbol.toStringTag];
  var jwkMatchesOp = (entry, key, usage) => {
    const { alg } = entry;
    if (key.use !== void 0) {
      const expected = usage === "sign" || usage === "verify" ? "sig" : "enc";
      if (key.use !== expected) {
        throw new TypeError(`Invalid key for this operation, its "use" must be "${expected}" when present`);
      }
    }
    if (key.alg !== void 0 && key.alg !== alg) {
      throw new TypeError(`Invalid key for this operation, its "alg" must be "${alg}" when present`);
    }
    if (Array.isArray(key.key_ops)) {
      const expectedKeyOp = usage === "encrypt" || usage === "decrypt" ? entry.ops?.[usage === "encrypt" ? 0 : 1] : usage;
      if (expectedKeyOp && !key.key_ops.includes(expectedKeyOp)) {
        throw new TypeError(`Invalid key for this operation, its "key_ops" must include "${expectedKeyOp}" when present`);
      }
    }
  };
  function checkKeyType(entry, key, usage) {
    const { alg, secret } = entry;
    const privateKey = usage === "decrypt" || usage === "sign";
    if (secret && key instanceof Uint8Array)
      return [BYTES, key];
    if (isObject(key)) {
      const normalized = normalizeJwk(key);
      if (typeof normalized.kty !== "string") {
        throw new TypeError(secret ? withAlg(alg, key, "CryptoKey", "KeyObject", "JSON Web Key", "Uint8Array") : withAlg(alg, key, "CryptoKey", "KeyObject", "JSON Web Key"));
      }
      const valid = secret ? normalized.kty === "oct" && typeof normalized.k === "string" : normalized.kty !== "oct" && (privateKey ? normalized.kty === "AKP" && typeof normalized.priv === "string" || typeof normalized.d === "string" : normalized.d === void 0 && normalized.priv === void 0);
      if (!valid) {
        throw new TypeError(secret ? `JSON Web Key for symmetric algorithms must have JWK "kty" (Key Type) equal to "oct" and the JWK "k" (Key Value) present` : `JSON Web Key for this operation must be a ${privateKey ? "private" : "public"} JWK`);
      }
      jwkMatchesOp(entry, normalized, usage);
      return [JWK, key, normalized];
    }
    if (!isKeyLike(key)) {
      throw new TypeError(secret ? withAlg(alg, key, "CryptoKey", "KeyObject", "JSON Web Key", "Uint8Array") : withAlg(alg, key, "CryptoKey", "KeyObject", "JSON Web Key"));
    }
    if (secret) {
      if (key.type !== "secret") {
        throw new TypeError(`${tag(key)} instances for symmetric algorithms must be of type "secret"`);
      }
    } else {
      if (key.type === "secret") {
        throw new TypeError(`${tag(key)} instances for asymmetric algorithms must not be of type "secret"`);
      }
      const expectedType = privateKey ? "private" : "public";
      if ((key.type === "public" || key.type === "private") && key.type !== expectedType) {
        const operation = usage === "sign" ? "signing" : usage === "verify" ? "verifying" : `${usage.slice(0, -1)}tion`;
        throw new TypeError(`${tag(key)} instances for asymmetric algorithm ${operation} must be of type "${expectedType}"`);
      }
    }
    return isCryptoKey(key) ? [CRYPTO, key] : [KEYOBJECT, key];
  }
  var BYTES = 0;
  var CRYPTO = 1;
  var KEYOBJECT = 2;
  var JWK = 3;
  var cache;
  var nist = {
    __proto__: null,
    prime256v1: "P-256",
    secp384r1: "P-384",
    secp521r1: "P-521"
  };
  function cached(key, alg, value) {
    cache ||= /* @__PURE__ */ new WeakMap();
    const entry = cache.get(key);
    if (value) {
      if (entry) {
        entry[alg] = value;
      } else {
        cache.set(key, { [alg]: value });
      }
    }
    return value ?? entry?.[alg];
  }
  var handleJWK = async (key, jwk2, entry) => cached(key, entry.alg) ?? cached(key, entry.alg, await jwkToKey(entry, { ...jwk2, alg: entry.alg }));
  var handleKeyObject = (keyObject, entry) => {
    const hit = cached(keyObject, entry.alg);
    if (hit)
      return hit;
    const isPublic = keyObject.type === "public";
    const usages = entry.usages[isPublic ? 0 : 1];
    const { asymmetricKeyType } = keyObject;
    const crv = nist[keyObject.asymmetricKeyDetails?.namedCurve];
    const params = entry.resolve?.({ crv, asymmetricKeyType }) ?? entry.subtle;
    return cached(keyObject, entry.alg, keyObject.toCryptoKey(params, isPublic, usages));
  };
  async function prepareKey(entry, key, usage) {
    const tagged = checkKeyType(entry, key, usage);
    switch (tagged[0]) {
      case BYTES:
      case CRYPTO:
        return tagged[1];
      case JWK: {
        const key2 = tagged[1];
        const normalized = tagged[2];
        if (normalized.kty === "oct") {
          return decode(normalized.k);
        }
        if (!Object.isFrozen(key2)) {
          const { key_ops } = key2;
          if (Array.isArray(key_ops))
            Object.freeze(key_ops);
          Object.freeze(key2);
        }
        return handleJWK(key2, normalized, entry);
      }
      case KEYOBJECT: {
        const keyObject = tagged[1];
        if (keyObject.type === "secret") {
          return keyObject.export();
        }
        if ("toCryptoKey" in keyObject && typeof keyObject.toCryptoKey === "function") {
          return handleKeyObject(keyObject, entry);
        }
        return handleJWK(keyObject, keyObject.export({ format: "jwk" }), entry);
      }
    }
  }

  // node_modules/jose/dist/webapi/lib/key_descriptor.js
  function table(entries) {
    const out = { __proto__: null };
    for (const alg in entries) {
      out[alg] = { ...entries[alg], alg };
    }
    return out;
  }

  // node_modules/jose/dist/webapi/lib/jwe_algorithms.js
  var wrap = [
    ["encrypt", "wrapKey"],
    ["decrypt", "unwrapKey"]
  ];
  var derive = [[], ["deriveBits"]];
  var none = [[], []];
  function rsaes(bits) {
    return {
      kty: ["RSA"],
      subtle: { name: "RSA-OAEP", hash: `SHA-${bits}` },
      usages: wrap,
      ops: ["wrapKey", "unwrapKey"]
    };
  }
  function ecdh() {
    return {
      kty: ["EC", "OKP"],
      subtle: { name: "ECDH" },
      resolve: ({ kty, crv, asymmetricKeyType }) => {
        if (crv === "X25519" || asymmetricKeyType === "x25519") {
          return { name: "X25519" };
        }
        if (kty === "OKP") {
          throw new JOSENotSupported('Invalid or unsupported JWK "alg" (Algorithm) Parameter value');
        }
        return { name: "ECDH", namedCurve: crv };
      },
      usages: derive,
      ops: [void 0, "deriveBits"]
    };
  }
  function aeskw(bits, gcm = false) {
    return {
      kty: ["oct"],
      secret: true,
      subtle: { name: gcm ? "AES-GCM" : "AES-KW", length: bits },
      usages: none,
      ops: gcm ? ["encrypt", "decrypt"] : ["wrapKey", "unwrapKey"]
    };
  }
  function pbes2() {
    return {
      kty: ["oct"],
      secret: true,
      subtle: { name: "PBKDF2" },
      usages: none,
      ops: ["deriveBits", "deriveBits"]
    };
  }
  var JWE = table({
    dir: {
      kty: ["oct"],
      secret: true,
      subtle: { name: "AES-GCM" },
      usages: none,
      ops: ["encrypt", "decrypt"]
    },
    "RSA-OAEP": rsaes(1),
    "RSA-OAEP-256": rsaes(256),
    "RSA-OAEP-384": rsaes(384),
    "RSA-OAEP-512": rsaes(512),
    "ECDH-ES": ecdh(),
    "ECDH-ES+A128KW": ecdh(),
    "ECDH-ES+A192KW": ecdh(),
    "ECDH-ES+A256KW": ecdh(),
    A128KW: aeskw(128),
    A192KW: aeskw(192),
    A256KW: aeskw(256),
    A128GCMKW: aeskw(128, true),
    A192GCMKW: aeskw(192, true),
    A256GCMKW: aeskw(256, true),
    "PBES2-HS256+A128KW": pbes2(),
    "PBES2-HS384+A192KW": pbes2(),
    "PBES2-HS512+A256KW": pbes2()
  });
  var contentOps = ["encrypt", "decrypt"];
  function contentEncryption(bits, cbc = false) {
    return {
      kty: ["oct"],
      secret: true,
      subtle: { name: cbc ? "AES-CBC" : "AES-GCM", length: bits },
      usages: none,
      ops: contentOps,
      cekBits: bits,
      ivBits: cbc ? 128 : 96,
      cbc
    };
  }
  var ENC = table({
    A128GCM: contentEncryption(128),
    A192GCM: contentEncryption(192),
    A256GCM: contentEncryption(256),
    "A128CBC-HS256": contentEncryption(256, true),
    "A192CBC-HS384": contentEncryption(384, true),
    "A256CBC-HS512": contentEncryption(512, true)
  });
  function unsupported(parameter, name) {
    throw new JOSENotSupported(`Invalid or unsupported "${parameter}" (JWE ${name}) header value`);
  }
  function jweAlgorithm(alg) {
    return (typeof alg === "string" ? JWE[alg] : void 0) ?? unsupported("alg", "Algorithm");
  }
  function jweEncryption(enc) {
    return (typeof enc === "string" ? ENC[enc] : void 0) ?? unsupported("enc", "Encryption Algorithm");
  }

  // node_modules/jose/dist/webapi/lib/key_management.js
  function checkEcdhCryptoKey(key, usage) {
    if (key.algorithm.name !== "ECDH" && key.algorithm.name !== "X25519") {
      throw new TypeError("CryptoKey does not support this operation, its algorithm.name must be ECDH or X25519");
    }
    checkUsage(key, usage);
  }
  async function aeskwCryptoKey(key, alg, usage) {
    const expected = jweAlgorithm(alg).subtle;
    const cryptoKey = key instanceof Uint8Array ? await crypto.subtle.importKey("raw", key, "AES-KW", true, [
      usage
    ]) : key;
    checkCryptoKey(cryptoKey, expected, usage);
    return cryptoKey;
  }
  async function aeskwWrap(alg, key, cek) {
    const cryptoKey = await aeskwCryptoKey(key, alg, "wrapKey");
    const cryptoKeyCek = await crypto.subtle.importKey("raw", cek, { hash: "SHA-256", name: "HMAC" }, true, ["sign"]);
    return new Uint8Array(await crypto.subtle.wrapKey("raw", cryptoKeyCek, cryptoKey, "AES-KW"));
  }
  function checkRsaKey(alg, key, usage) {
    checkCryptoKey(key, jweAlgorithm(alg).subtle, usage);
    checkModulusLength(alg, key);
  }
  function pbes2CryptoKey(key, alg) {
    if (key instanceof Uint8Array) {
      return crypto.subtle.importKey("raw", key, "PBKDF2", false, [
        "deriveBits"
      ]);
    }
    checkCryptoKey(key, jweAlgorithm(alg).subtle, "deriveBits");
    return key;
  }
  async function deriveKey(p2s, alg, p2c, key) {
    if (!(p2s instanceof Uint8Array) || p2s.length < 8) {
      throw new JWEInvalid("PBES2 Salt Input must be 8 or more octets");
    }
    if (!Number.isSafeInteger(p2c) || Math.sign(p2c) !== 1) {
      throw new JWEInvalid("PBES2 Count Input must be a positive integer");
    }
    const salt = concat(encode(alg), Uint8Array.of(0), p2s);
    const keylen = parseInt(alg.slice(13, 16), 10);
    const subtleAlg = {
      hash: `SHA-${alg.slice(8, 11)}`,
      iterations: p2c,
      name: "PBKDF2",
      salt
    };
    const cryptoKey = await pbes2CryptoKey(key, alg);
    return new Uint8Array(await crypto.subtle.deriveBits(subtleAlg, cryptoKey, keylen));
  }
  function lengthAndInput(input) {
    return concat(uint32be(input.length), input);
  }
  async function concatKdf(Z, L, OtherInfo) {
    const dkLen = L >> 3;
    const hashLen = 32;
    const reps = Math.ceil(dkLen / hashLen);
    const dk = new Uint8Array(reps * hashLen);
    for (let i = 1; i <= reps; i++) {
      const hashResult = await digest("sha256", concat(uint32be(i), Z, OtherInfo));
      dk.set(hashResult, (i - 1) * hashLen);
    }
    return dk.slice(0, dkLen);
  }
  async function ecdhesDeriveKey(publicKey, privateKey, algorithm, keyLength, apu = new Uint8Array(), apv = new Uint8Array()) {
    checkEcdhCryptoKey(publicKey);
    checkEcdhCryptoKey(privateKey, "deriveBits");
    const otherInfo = concat(lengthAndInput(encode(algorithm)), lengthAndInput(apu), lengthAndInput(apv), uint32be(keyLength));
    const Z = new Uint8Array(await crypto.subtle.deriveBits({
      name: publicKey.algorithm.name,
      public: publicKey
    }, privateKey, publicKey.algorithm.name === "X25519" ? 256 : Math.ceil(parseInt(publicKey.algorithm.namedCurve.slice(-3), 10) / 8) << 3));
    return concatKdf(Z, keyLength, otherInfo);
  }
  function assertEcdhKey(key) {
    assertCryptoKey(key);
    const curve = key.algorithm.namedCurve;
    if (curve !== "P-256" && curve !== "P-384" && curve !== "P-521" && key.algorithm.name !== "X25519") {
      throw new JOSENotSupported("ECDH with the provided key is not allowed or not supported by your javascript runtime");
    }
  }
  async function encryptKeyManagement(alg, enc, key, providedCek, providedParameters = {}) {
    let encryptedKey;
    let parameters;
    let cek;
    const entry = jweAlgorithm(alg);
    if (alg === "dir")
      return [key, void 0, void 0];
    switch (entry.subtle.name) {
      case "ECDH": {
        assertEcdhKey(key);
        const { apu, apv } = providedParameters;
        if (apu !== void 0) {
          assertUint8Array(apu, '"apu"');
        }
        if (apv !== void 0) {
          assertUint8Array(apv, '"apv"');
        }
        let ephemeralKey;
        if (providedParameters.epk !== void 0) {
          ephemeralKey = await prepareKey(entry, providedParameters.epk, "decrypt");
        } else {
          ephemeralKey = (await crypto.subtle.generateKey(key.algorithm, true, ["deriveBits"])).privateKey;
        }
        const subtle = crypto.subtle;
        let exportableEpk = ephemeralKey;
        if (!exportableEpk.extractable) {
          if (typeof subtle.getPublicKey !== "function") {
            throw new TypeError('CryptoKey for "epk" must be extractable');
          }
          exportableEpk = await subtle.getPublicKey(ephemeralKey, []);
        }
        const { x, y, crv, kty } = await subtle.exportKey("jwk", exportableEpk);
        const sharedSecret = await ecdhesDeriveKey(key, ephemeralKey, alg === "ECDH-ES" ? enc.alg : alg, alg === "ECDH-ES" ? enc.cekBits : parseInt(alg.slice(-5, -2), 10), apu, apv);
        parameters = { epk: { x, crv, kty } };
        if (kty === "EC")
          parameters.epk.y = y;
        if (apu)
          parameters.apu = encode2(apu);
        if (apv)
          parameters.apv = encode2(apv);
        if (alg === "ECDH-ES") {
          cek = sharedSecret;
          break;
        }
        cek = providedCek || generateCek(enc);
        const kwAlg = alg.slice(-6);
        encryptedKey = await aeskwWrap(kwAlg, sharedSecret, cek);
        break;
      }
      case "RSA-OAEP": {
        cek = providedCek || generateCek(enc);
        assertCryptoKey(key);
        checkRsaKey(alg, key, "encrypt");
        encryptedKey = new Uint8Array(await crypto.subtle.encrypt("RSA-OAEP", key, cek));
        break;
      }
      case "PBKDF2": {
        cek = providedCek || generateCek(enc);
        const { p2c = 2048, p2s = crypto.getRandomValues(new Uint8Array(16)) } = providedParameters;
        const derived = await deriveKey(p2s, alg, p2c, key);
        encryptedKey = await aeskwWrap(alg.slice(-6), derived, cek);
        parameters = { p2c, p2s: encode2(p2s) };
        break;
      }
      case "AES-KW": {
        cek = providedCek || generateCek(enc);
        encryptedKey = await aeskwWrap(alg, key, cek);
        break;
      }
      case "AES-GCM": {
        cek = providedCek || generateCek(enc);
        const { iv } = providedParameters;
        const wrapped = await encrypt(jweEncryption(alg.slice(0, -2)), cek, key, iv, new Uint8Array());
        encryptedKey = wrapped.ciphertext;
        parameters = { iv: encode2(wrapped.iv), tag: encode2(wrapped.tag) };
        break;
      }
    }
    return [cek, encryptedKey, parameters];
  }

  // node_modules/jose/dist/webapi/lib/options.js
  var JWE_RECOGNIZED = { __proto__: null };
  function validateCritDuplicates(Err, protectedHeader) {
    const { crit } = protectedHeader ?? {};
    if (Array.isArray(crit) && new Set(crit).size !== crit.length) {
      throw new Err('"crit" (Critical) Header Parameter MUST NOT contain duplicate values');
    }
  }
  function validateCrit(Err, recognizedDefault, recognizedOption, protectedHeader, joseHeader) {
    if (joseHeader.crit !== void 0 && protectedHeader?.crit === void 0) {
      throw new Err('"crit" (Critical) Header Parameter MUST be integrity protected');
    }
    if (!protectedHeader || protectedHeader.crit === void 0) {
      return [];
    }
    if (!Array.isArray(protectedHeader.crit) || protectedHeader.crit.length === 0 || protectedHeader.crit.some((input) => typeof input !== "string" || input.length === 0)) {
      throw new Err('"crit" (Critical) Header Parameter MUST be an array of non-empty strings when present');
    }
    const recognized = recognizedOption === void 0 ? recognizedDefault : { __proto__: null, ...recognizedOption, ...recognizedDefault };
    for (const parameter of protectedHeader.crit) {
      if (!(parameter in recognized)) {
        throw new JOSENotSupported(`Extension Header Parameter "${parameter}" is not recognized`);
      }
      if (!Object.hasOwn(joseHeader, parameter) || joseHeader[parameter] === void 0) {
        throw new Err(`Extension Header Parameter "${parameter}" is missing`);
      }
      if (recognized[parameter] && (!Object.hasOwn(protectedHeader, parameter) || protectedHeader[parameter] === void 0)) {
        throw new Err(`Extension Header Parameter "${parameter}" MUST be integrity protected`);
      }
    }
    return protectedHeader.crit;
  }
  function serializeJoseHeader(Err, header) {
    let serialized;
    let parsed;
    try {
      serialized = JSON.stringify(header);
      parsed = JSON.parse(serialized);
    } catch (cause) {
      throw new Err("JOSE Header is not valid JSON", { cause });
    }
    if (!isObject(parsed)) {
      throw new Err("JOSE Header is not a JSON object");
    }
    return [parsed, serialized];
  }

  // node_modules/jose/dist/webapi/lib/deflate.js
  function validateZip(joseHeader, protectedHeader) {
    if (joseHeader.zip !== void 0 && joseHeader.zip !== "DEF") {
      throw new JOSENotSupported('Unsupported JWE "zip" (Compression Algorithm) Header Parameter value.');
    }
    if (joseHeader.zip !== void 0 && !protectedHeader?.zip) {
      throw new JWEInvalid('JWE "zip" (Compression Algorithm) Header Parameter MUST be in a protected header.');
    }
  }
  function supported(name) {
    if (typeof globalThis[name] === "undefined") {
      throw new JOSENotSupported(`JWE "zip" (Compression Algorithm) Header Parameter requires the ${name} API.`);
    }
  }
  async function compress(input) {
    supported("CompressionStream");
    const cs = new CompressionStream("deflate-raw");
    const writer = cs.writable.getWriter();
    writer.write(input).catch(() => {
    });
    writer.close().catch(() => {
    });
    const chunks = [];
    const reader = cs.readable.getReader();
    for (; ; ) {
      const { value, done } = await reader.read();
      if (done)
        break;
      chunks.push(value);
    }
    return concat(...chunks);
  }

  // node_modules/jose/dist/webapi/lib/jwe_encrypt.js
  function checkDisjoint(protectedHeader, unprotectedHeader, sharedUnprotectedHeader) {
    if (!isDisjoint(protectedHeader, unprotectedHeader, sharedUnprotectedHeader)) {
      throw new JWEInvalid("JWE Protected, JWE Shared Unprotected and JWE Per-Recipient Header Parameter names must be disjoint");
    }
  }
  function checkEncryptHeaders(input) {
    let [, protectedHeader, unprotectedHeader, sharedUnprotectedHeader, aad, cek, iv, keyManagementParameters, crit] = input;
    if (aad !== void 0) {
      assertUint8Array(aad, "JWE Additional Authenticated Data");
    }
    if (cek !== void 0) {
      assertUint8Array(cek, "JWE Content Encryption Key");
    }
    if (iv !== void 0) {
      assertUint8Array(iv, "JWE Initialization Vector");
    }
    if (protectedHeader !== void 0) {
      protectedHeader = serializeJoseHeader(JWEInvalid, protectedHeader)[0];
      input[1] = protectedHeader;
    }
    if (unprotectedHeader !== void 0) {
      unprotectedHeader = serializeJoseHeader(JWEInvalid, unprotectedHeader)[0];
      input[2] = unprotectedHeader;
    }
    if (sharedUnprotectedHeader !== void 0) {
      sharedUnprotectedHeader = serializeJoseHeader(JWEInvalid, sharedUnprotectedHeader)[0];
      input[3] = sharedUnprotectedHeader;
    }
    if (keyManagementParameters !== void 0 && !isObject(keyManagementParameters)) {
      throw new TypeError("JWE Key Management Parameters must be an object");
    }
    checkDisjoint(protectedHeader, unprotectedHeader, sharedUnprotectedHeader);
    const joseHeader = {
      ...protectedHeader,
      ...unprotectedHeader,
      ...sharedUnprotectedHeader
    };
    validateCritDuplicates(JWEInvalid, protectedHeader);
    validateCrit(JWEInvalid, JWE_RECOGNIZED, crit, protectedHeader, joseHeader);
    validateZip(joseHeader, protectedHeader);
    const { alg, enc } = joseHeader;
    if (typeof alg !== "string" || !alg) {
      throw new JWEInvalid('JWE "alg" (Algorithm) Header Parameter missing or invalid');
    }
    if (typeof enc !== "string" || !enc) {
      throw new JWEInvalid('JWE "enc" (Encryption Algorithm) Header Parameter missing or invalid');
    }
    return [joseHeader, alg, enc, jweEncryption(enc)];
  }
  async function encryptJWE(input, checked, key) {
    const [joseHeader, alg, , encEntry] = checked;
    const [inputPlaintext, inputProtectedHeader, inputUnprotectedHeader, sharedUnprotectedHeader, aad, providedCek, inputIv, keyManagementParameters, , unprotectedParameters] = input;
    let protectedHeader = inputProtectedHeader;
    let unprotectedHeader = inputUnprotectedHeader;
    if (providedCek && (alg === "dir" || alg === "ECDH-ES")) {
      throw new TypeError(`setContentEncryptionKey cannot be called with JWE "alg" (Algorithm) Header ${alg}`);
    }
    const algEntry = jweAlgorithm(alg);
    const k = await prepareKey(alg === "dir" ? encEntry : algEntry, key, "encrypt");
    const [cek, encryptedKey, parameters] = await encryptKeyManagement(alg, encEntry, k, providedCek, keyManagementParameters);
    if (parameters) {
      if (unprotectedParameters) {
        unprotectedHeader = unprotectedHeader ? { ...unprotectedHeader, ...parameters } : parameters;
      } else {
        protectedHeader = protectedHeader ? { ...protectedHeader, ...parameters } : parameters;
      }
      checkDisjoint(protectedHeader, unprotectedHeader, sharedUnprotectedHeader);
    }
    let protectedHeaderS;
    let protectedHeaderB;
    if (protectedHeader) {
      protectedHeaderS = encode2(JSON.stringify(protectedHeader));
      protectedHeaderB = encode(protectedHeaderS);
    } else {
      protectedHeaderS = "";
      protectedHeaderB = new Uint8Array();
    }
    let additionalData;
    let aadMember;
    if (aad?.byteLength) {
      aadMember = encode2(aad);
      additionalData = concat(protectedHeaderB, encode("."), encode(aadMember));
    } else {
      additionalData = protectedHeaderB;
    }
    let plaintext = inputPlaintext;
    if (joseHeader.zip === "DEF") {
      plaintext = await compress(plaintext).catch((cause) => {
        throw new JWEInvalid("Failed to compress plaintext", { cause });
      });
    }
    const { ciphertext, tag: tag2, iv } = await encrypt(encEntry, plaintext, cek, inputIv, additionalData);
    const jwe = {
      ciphertext: encode2(ciphertext)
    };
    if (iv) {
      jwe.iv = encode2(iv);
    }
    if (tag2) {
      jwe.tag = encode2(tag2);
    }
    if (encryptedKey) {
      jwe.encrypted_key = encode2(encryptedKey);
    }
    if (aadMember) {
      jwe.aad = aadMember;
    }
    if (protectedHeader) {
      jwe.protected = protectedHeaderS;
    }
    if (sharedUnprotectedHeader) {
      jwe.unprotected = sharedUnprotectedHeader;
    }
    if (unprotectedHeader) {
      jwe.header = unprotectedHeader;
    }
    return jwe;
  }
  async function createJWE(input, key, options) {
    if (!input[1] && !input[2] && !input[3]) {
      throw new JWEInvalid("either setProtectedHeader, setUnprotectedHeader, or sharedUnprotectedHeader must be called before #encrypt()");
    }
    if (options !== void 0) {
      input[8] = options?.crit;
      input[9] = options ? unprotected in options : false;
    }
    return encryptJWE(input, checkEncryptHeaders(input), key);
  }

  // node_modules/jose/dist/webapi/lib/jws_algorithms.js
  var sig = [["verify"], ["sign"]];
  function hmac(bits) {
    const subtle = { name: "HMAC", hash: `SHA-${bits}` };
    return { kty: ["oct"], secret: true, subtle, signing: subtle, usages: sig };
  }
  function rsa(bits, saltLength) {
    const name = saltLength ? "RSA-PSS" : "RSASSA-PKCS1-v1_5";
    const subtle = { name, hash: `SHA-${bits}` };
    return {
      kty: ["RSA"],
      subtle,
      signing: saltLength ? { ...subtle, saltLength } : subtle,
      usages: sig,
      minRsaBits: 2048
    };
  }
  function ecdsa(crv, bits) {
    return {
      kty: ["EC"],
      crv,
      subtle: { name: "ECDSA", namedCurve: crv },
      signing: { name: "ECDSA", hash: `SHA-${bits}` },
      usages: sig
    };
  }
  function eddsa() {
    const subtle = { name: "Ed25519" };
    return {
      kty: ["OKP"],
      crv: "Ed25519",
      subtle,
      signing: subtle,
      usages: sig
    };
  }
  function mldsa(bits) {
    const name = `ML-DSA-${bits}`;
    const subtle = { name };
    return {
      kty: ["AKP"],
      subtle,
      signing: subtle,
      usages: sig
    };
  }
  var JWS = table({
    HS256: hmac(256),
    HS384: hmac(384),
    HS512: hmac(512),
    RS256: rsa(256),
    RS384: rsa(384),
    RS512: rsa(512),
    PS256: rsa(256, 32),
    PS384: rsa(384, 48),
    PS512: rsa(512, 64),
    ES256: ecdsa("P-256", 256),
    ES384: ecdsa("P-384", 384),
    ES512: ecdsa("P-521", 512),
    EdDSA: eddsa(),
    Ed25519: eddsa(),
    "ML-DSA-44": mldsa(44),
    "ML-DSA-65": mldsa(65),
    "ML-DSA-87": mldsa(87)
  });

  // node_modules/jose/dist/webapi/jwe/compact/encrypt.js
  var CompactEncrypt = class {
    #plaintext;
    #protectedHeader;
    #cek;
    #iv;
    #keyManagementParameters;
    constructor(plaintext) {
      assertUint8Array(plaintext, "plaintext");
      this.#plaintext = plaintext;
    }
    setContentEncryptionKey(cek) {
      assertNotSet(this.#cek, "setContentEncryptionKey");
      this.#cek = cek;
      return this;
    }
    setInitializationVector(iv) {
      assertNotSet(this.#iv, "setInitializationVector");
      this.#iv = iv;
      return this;
    }
    setProtectedHeader(protectedHeader) {
      assertNotSet(this.#protectedHeader, "setProtectedHeader");
      this.#protectedHeader = protectedHeader;
      return this;
    }
    setKeyManagementParameters(parameters) {
      assertNotSet(this.#keyManagementParameters, "setKeyManagementParameters");
      this.#keyManagementParameters = parameters;
      return this;
    }
    async encrypt(key, options) {
      const jwe = await createJWE([
        this.#plaintext,
        this.#protectedHeader,
        void 0,
        void 0,
        void 0,
        this.#cek,
        this.#iv,
        this.#keyManagementParameters,
        void 0,
        false
      ], key, options);
      return [jwe.protected, jwe.encrypted_key, jwe.iv, jwe.ciphertext, jwe.tag].join(".");
    }
  };

  // node_modules/jose/dist/webapi/lib/key_algorithm.js
  function unsupportedAlg(source = 'JWK "alg" (Algorithm) Parameter') {
    throw new JOSENotSupported(`Invalid or unsupported ${source} value`);
  }
  function keyAlgorithm(alg, source) {
    return (typeof alg === "string" ? JWS[alg] ?? JWE[alg] : void 0) ?? unsupportedAlg(source);
  }

  // node_modules/jose/dist/webapi/lib/key_options.js
  function validateExtractableOption(extractable) {
    if (extractable !== void 0 && typeof extractable !== "boolean") {
      throw new TypeError('"extractable" option must be a boolean');
    }
    return extractable;
  }

  // node_modules/jose/dist/webapi/key/import.js
  async function importJWK(jwk2, alg, options) {
    if (!isObject(jwk2)) {
      throw new TypeError("JWK must be an object");
    }
    const normalized = normalizeJwk(jwk2);
    const extractable = validateExtractableOption(options?.extractable);
    const { alg: jwkAlg } = normalized;
    alg ??= jwkAlg;
    const ext = extractable ?? normalized.ext;
    if (normalized.kty !== "oct" && !alg) {
      throw new TypeError('"alg" argument is required when "jwk.alg" is not present');
    }
    switch (normalized.kty) {
      case "oct":
        if (typeof normalized.k !== "string") {
          throw new TypeError('missing "k" (Key Value) Parameter value');
        }
        return decode(normalized.k);
      case "AKP": {
        if (typeof jwkAlg !== "string" || !jwkAlg) {
          throw new TypeError('missing "alg" (Algorithm) Parameter value');
        }
        if (alg !== jwkAlg) {
          throw new TypeError("JWK alg and alg option value mismatch");
        }
        return jwkToKey(keyAlgorithm(alg), { ...normalized, ext });
      }
      case "RSA":
      case "EC":
      case "OKP":
        return jwkToKey(keyAlgorithm(alg), { ...normalized, alg, ext });
      default:
        throw new JOSENotSupported('Unsupported "kty" (Key Type) Parameter value');
    }
  }

  // node_modules/zotero-plugin/dist/esm/debug-log.js
  var UZip = __toESM(require_UZIP(), 1);
  var KEYTYPE = "RSA";
  var KEY_WRAPPING_ALG = "RSA-OAEP-256";
  var CONTENT_ENCRYPTION_ALG = "A256GCM";
  Components.utils.importGlobalProperties(["FormData"]);
  var Bundler = class {
    key;
    #refs = false;
    #pk;
    #pubKey;
    #files = {};
    #encoder = new TextEncoder();
    constructor(pk) {
      this.key = Zotero.Utilities.generateObjectKey();
      if (pk && pk.kty === KEYTYPE) this.#pk = pk;
    }
    async add(path, data, refs = false) {
      this.#refs = this.#refs || refs;
      const encoded = this.#encoder.encode(data);
      if (this.#pk) {
        if (!this.#pubKey) this.#pubKey = await importJWK(this.#pk, KEY_WRAPPING_ALG);
        const jwe = await new CompactEncrypt(encoded).setProtectedHeader({
          alg: KEY_WRAPPING_ALG,
          enc: CONTENT_ENCRYPTION_ALG
        }).encrypt(this.#pubKey);
        this.#files[`${this.key}/${path}.jwe`] = this.#encoder.encode(jwe);
      } else {
        this.#files[`${this.key}/${path}`] = encoded;
      }
    }
    get zip() {
      return UZip.encode(this.#files);
    }
    get name() {
      return `${this.key}.zip`;
    }
    id(host) {
      return `${this.key}-${host}${this.#refs ? ".refs" : ""}${this.#pubKey ? ".enc" : ""}`;
    }
    async send() {
      const response = await fetch(`https://filebin.net/${this.key}/${this.name}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/zip"
        },
        body: new Blob([this.zip], { type: "application/zip" })
      });
      if (response.ok) return this.id("fbin");
      throw new Error(await response.text());
    }
  };
  var zotero_prefs_root = "extensions.zotero.";
  var DebugLogSender = class {
    constructor(pluginID, label, preferences = [], pubKey) {
      this.pluginID = pluginID;
      this.label = label;
      this.pubKey = pubKey;
      this.#preferences = preferences;
      Zotero.MenuManager.registerMenu({
        menuID: `debug-log-sender-${pluginID}`,
        pluginID,
        target: "main/menubar/help",
        menus: [
          {
            menuType: "menuitem",
            onShowing: (event, context) => {
              context.setVisible(this.enabled);
              context.menuElem?.setAttribute("label", this.label);
            },
            onCommand: (event, context) => {
              void this.send();
            }
          }
        ]
      });
    }
    pluginID;
    label;
    pubKey;
    // #menu: string | false = false
    #preferences;
    enabled = false;
    debugEnabledAtStart = Zotero.Prefs.get("debug.store") || Zotero.Debug.enabled;
    async send() {
      try {
        await Zotero.Schema.schemaUpdatePromise;
        const bundler = new Bundler(this.pubKey || void 0);
        let log2 = [
          await this.info(),
          Zotero.getErrors(true).join("\n\n"),
          Zotero.Debug.getConsoleViewerOutput().slice(-25e4).join("\n")
          // eslint-disable-line no-magic-numbers
        ].filter((txt) => txt).join("\n\n").trim();
        await bundler.add("debug.txt", log2);
        let rdf = await this.rdf();
        if (rdf) await bundler.add("items.rdf", rdf, true);
        const logid = await bundler.send();
        Services.prompt.alert(null, `Debug log ID for ${this.label}`, logid);
      } catch (err) {
        const message2 = err instanceof Error ? err.message : String(err);
        Services.prompt.alert(null, `Could not post debug log for ${this.label}`, message2);
      }
    }
    preferences() {
      const prefs = {};
      const names = [];
      for (let pref of this.#preferences) {
        if (pref[0] === ":") {
          pref = pref.substring(1);
        } else if (!pref.startsWith(zotero_prefs_root)) {
          pref = zotero_prefs_root + pref;
        }
        if (pref.endsWith(".")) {
          const childkeys = Services.prefs.getBranch(pref).getChildList("", {});
          for (const key of childkeys) {
            names.push(pref + key);
          }
        } else {
          names.push(pref);
        }
      }
      for (const pref of names.sort()) {
        const value = Zotero.Prefs.get(pref, true);
        if (typeof value !== "undefined") prefs[pref] = value;
      }
      return prefs;
    }
    // general state of Zotero
    async info() {
      let info = "";
      const appInfo = Components.classes["@mozilla.org/xre/app-info;1"].getService(Components.interfaces.nsIXULAppInfo);
      info += `Application: ${appInfo.name} ${appInfo.version} ${Zotero.locale}
`;
      const platformFlags = Zotero;
      const platform = ["Win", "Mac", "Linux"].find((p) => Boolean(platformFlags[`is${p}`])) || "Unknown";
      info += `Platform: ${platform}
`;
      const addons = await Zotero.getInstalledExtensions();
      if (addons.length) {
        info += "Addons:\n" + addons.map((addon) => `  ${addon}
`).join("");
      }
      info += `Debug logging on at Zotero start: ${this.debugEnabledAtStart}
`;
      info += `Debug logging on at log submit: ${Zotero.Prefs.get("debug.store") || Zotero.Debug.enabled}
`;
      for (const [pref, value] of Object.entries(this.preferences())) {
        info += `${pref} = ${JSON.stringify(value)}
`;
      }
      return info;
    }
    rdf() {
      return new Promise((resolve, reject) => {
        const pane = Zotero.getActiveZoteroPane();
        if (!pane) return resolve("");
        const items = pane.getSelectedItems();
        if (items.length === 0) return resolve("");
        const translation = new Zotero.Translate.Export();
        translation.setItems(items);
        translation.setTranslator("14763d24-8ba0-45df-8f52-b8d1108e7ac9");
        translation.setHandler("done", (obj, success) => {
          if (success) {
            resolve(obj?.string || "");
          } else {
            reject(new Error("translation failed"));
          }
        });
        translation.translate();
      });
    }
  };

  // content/monkey-patch.ts
  var Monkey = class {
    constructor(name) {
      this.name = name;
    }
    name;
    #enabled = false;
    #dead = false;
    #unpatchers = [];
    needsProxy(fn) {
      if (typeof fn !== "function") return false;
      if (Object.getOwnPropertyNames(fn).find((key) => !["length", "name", "prototype", "arguments", "caller"].includes(key))) return true;
      if (fn.prototype && fn.prototype.constructor === fn) return true;
      return false;
    }
    patch(obj, methodName, patcher) {
      if (!this.#unpatchers) {
        throw new Error(`${this.name}: Cannot patch after disable() has been called.`);
      }
      if (Cu.isDeadWrapper(obj[methodName])) {
        if (this.#dead) return;
        this.#dead = true;
        if (confirm({
          title: "Better BibTeX startup error",
          text: `Better BibTeX has experienced a startup error. Please restart Zotero to resolve it.
              If restarting does not resolve it, please report on
              https://github.com/retorquere/zotero-better-bibtex/issues/3590 .
              Do you want to restart now?`.replace(/  */g, " ")
        })) {
          Zotero.Utilities.Internal.quit(true);
        } else {
          return;
        }
      }
      const originalMethod = obj[methodName];
      const newMethod = patcher(originalMethod);
      let wrapper;
      const invoke = (thisArg, args) => {
        try {
          if (this.#enabled) {
            return newMethod.apply(thisArg, args);
          } else {
            return originalMethod.apply(thisArg, args);
          }
        } catch (err) {
          Zotero.debug(`${this.name} monkey-patch ${methodName} error: ${err.message}`);
          Zotero.logError(err);
          throw err;
        }
      };
      if (this.needsProxy(originalMethod)) {
        wrapper = new Proxy(originalMethod, {
          apply: (_target, thisArg, argumentsList) => invoke(thisArg, argumentsList),
          construct: (_target, argumentsList, newTarget) => {
            if (this.#enabled) {
              return Reflect.construct(newMethod, argumentsList, newTarget);
            }
            return Reflect.construct(originalMethod, argumentsList, newTarget);
          }
        });
      } else {
        wrapper = (...args) => invoke(obj, args);
      }
      this.#unpatchers.push(() => {
        if (obj[methodName] === wrapper) {
          obj[methodName] = originalMethod;
        }
      });
      obj[methodName] = wrapper;
    }
    enable() {
      if (!this.#unpatchers) {
        throw new Error(`${this.name}: Cannot enable a disabled patcher.`);
      }
      this.#enabled = true;
    }
    disable() {
      if (!this.#unpatchers) return;
      this.#enabled = false;
      for (const unpatch of this.#unpatchers) {
        unpatch?.();
      }
      this.#unpatchers = void 0;
    }
  };

  // content/bootstrap.ts
  var monkey;
  var BOOTSTRAP_REASONS = {
    1: "APP_STARTUP",
    2: "APP_SHUTDOWN",
    3: "ADDON_ENABLE",
    4: "ADDON_DISABLE",
    5: "ADDON_INSTALL",
    6: "ADDON_UNINSTALL",
    7: "ADDON_UPGRADE",
    8: "ADDON_DOWNGRADE"
  };
  function log(msg) {
    msg = `{better-bibtex} bootstrap: ${msg}`;
    if (Zotero?.debug) {
      Zotero.debug(`Better BibTeX bootstrap: ${msg}`);
    } else {
      dump(`${msg}
`);
    }
  }
  function install(_data, _reason) {
    log("install, nothing to do");
  }
  function onMainWindowLoad({ window }) {
    log("onMainWindowLoad");
    Zotero.BetterBibTeX.onMainWindowLoad({ window });
  }
  function onMainWindowUnload({ window }) {
    log("onMainWindowUnload");
    Zotero.BetterBibTeX.onMainWindowUnload({ window });
  }
  var chromeHandle = null;
  var sandbox = null;
  function makeSandbox(wantGlobalProperties = []) {
    const Sandbox = Components.utils.Sandbox;
    return new Sandbox(Components.utils.getObjectPrincipal(globalThis), {
      freshZone: true,
      freshCompartment: true,
      wantGlobalProperties
    });
  }
  async function startup({ resourceURI, rootURI = resourceURI.spec }, reason) {
    const prefix = "translators.better-bibtex.";
    const pluginID = "better-bibtex@iris-advies.com";
    const sender = new DebugLogSender(pluginID, "Fallback Better BibTeX debug log (if regular fails)", [prefix, `${prefix}$autoExport.`], jwk);
    sender.enabled = true;
    if (Zotero.BetterBibTeX) throw new Error("Better BibTeX is already started");
    Zotero.Debug.setStore(true);
    sandbox = makeSandbox([
      "atob",
      "btoa",
      "ChromeUtils",
      "DOMParser",
      "FormData",
      "structuredClone",
      "TextDecoder",
      "TextEncoder",
      "XMLHttpRequest",
      "URL",
      "URLSearchParams",
      "fetch"
    ]);
    try {
      log("startup started");
      const aomStartup = Cc["@mozilla.org/addons/addon-manager-startup;1"].getService(Ci.amIAddonManagerStartup);
      const manifestURI = Services.io.newURI(`${rootURI}manifest.json`);
      log(manifestURI.spec);
      chromeHandle = aomStartup.registerChrome(manifestURI, [
        ["content", "zotero-better-bibtex", "content/"],
        ["locale", "zotero-better-bibtex", "en-US", "locale/en-US/"],
        ["locale", "zotero-better-bibtex", "fr-FR", "locale/fr-FR/"],
        ["locale", "zotero-better-bibtex", "pt-BR", "locale/pt-BR/"],
        ["locale", "zotero-better-bibtex", "zh-CN", "locale/zh-CN/"],
        ["locale", "zotero-better-bibtex", "it-IT", "locale/it-IT/"]
      ]);
      const { FileUtils } = ChromeUtils.importESModule("resource://gre/modules/FileUtils.sys.mjs");
      monkey = new Monkey("better bibtex");
      Object.assign(Components.utils.waiveXrays(sandbox), {
        monkey,
        Zotero,
        ChromeWorker,
        rootURI,
        setTimeout,
        clearTimeout,
        setInterval,
        clearInterval,
        Localization,
        FileUtils,
        PathUtils,
        IOUtils
      });
      Services.scriptloader.loadSubScriptWithOptions(`${rootURI}content/better-bibtex.js`, {
        charset: "utf-8",
        target: sandbox
      });
      await Zotero.BetterBibTeX.startup(BOOTSTRAP_REASONS[reason]);
      log("startup done");
      sender.enabled = false;
    } catch (err) {
      alert({ title: "Better BibTeX startup failed", text: `${err}
${err.stack}` });
      log(`${err}
${err.stack}`);
    }
  }
  async function shutdown(data, reason) {
    try {
      log("shutdown started");
      monkey?.disable();
      monkey = void 0;
      if (typeof chromeHandle !== "undefined" && chromeHandle) {
        chromeHandle.destruct();
        chromeHandle = void 0;
      }
      if (Zotero.BetterBibTeX) {
        log("shutdown started");
        await Zotero.BetterBibTeX.shutdown(BOOTSTRAP_REASONS[reason]);
        log("shutdown completed");
        delete Zotero.BetterBibTeX;
        log("BBT deleted");
      }
      if (sandbox) Components.utils.nukeSandbox(sandbox);
      sandbox = null;
      log("bootstrap: shutdown: done");
    } catch (err) {
      alert({ title: "Better BibTeX shutdown failed", text: `${err}` });
      log(`${err}
${err.stack}`);
    }
  }
  function uninstall(_data, _reason) {
    log("uninstall, nothing to do");
  }
  return __toCommonJS(bootstrap_exports);
})();
//# sourceMappingURL=bootstrap.js.map
