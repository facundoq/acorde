import { LaCuerdaSource } from '../sources/LaCuerdaSource';

global.fetch = jest.fn();

describe('LaCuerdaSource - Fito Paez Case', () => {
  let source: LaCuerdaSource;

  beforeEach(() => {
    source = new LaCuerdaSource();
    jest.clearAllMocks();
  });

  const fitoPaezHtml = `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML lang='es'>
    <BODY>
        <div id='mCols'>
            <div id='mLeft'>
                <div id='rList' class='rList'>
                    <ul>
                        <li onclick='w.location="11_y_6"'>
                            <a href='11_y_6'>11 y 6</a>
                        </li>
                        <li onclick='w.location="mariposa_tecknicolor"'>
                            <a href='mariposa_tecknicolor'>Mariposa Tecknicolor</a>
                        </li>
                    </ul>
                </div>
            </div>
            <div class='mBody'>
                <div id=a_cont>
                    <ul id=b_main class=b_main onclick="bOpen(event)">
                        <li id='r000' lcd='RRTRKRRTR-967421835'>
                            <a href="11_y_6">
                                11 y 6 <em>acordes</em>
                            </A>
                        </li>
                        <li id='r172' lcd='RRRTTRTBK-621354789'>
                            <a href="mariposa_tecknicolor">
                                Mariposa Tecknicolor <em>acordes</em>
                            </A>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
        <div id='mBot'>
            <b>&copy;</b>
            LaCuerda<font color=#a0a0a0>.net</font>
             &middot <a href=//lacuerda.net/Extras/legal.php>aviso legal</a>
            &middot;<a href=//lacuerda.net/Extras/privpol.php>privacidad</a>
            &middot;<a href=//lacuerda.net/Extras/contacto.php>contacto</a>
        </div>
    </BODY>
</HTML>`;

  test('should parse songs correctly and ignore footer links', async () => {
    (global.fetch as jest.Mock).mockResolvedValue({
      ok: true,
      text: () => Promise.resolve(fitoPaezHtml),
    });
    
    const results = await source.search('Fito Paez');
    
    const titles = results.map(r => r.title.toLowerCase());
    
    // Check for expected songs
    expect(titles).toContain('11 y 6');
    expect(titles).toContain('mariposa tecknicolor');
    
    // Check that it DOES NOT contain footer links
    expect(titles).not.toContain('aviso legal');
    expect(titles).not.toContain('privacidad');
    expect(titles).not.toContain('contacto');
  });
});
