import {get_data} from './utils'
const {React, i18n} = Serverboards
const {object_is_equal, map_get, to_number, colorize_list_hex} = Serverboards.utils
const {Loading, Error} = Serverboards.Components

const _2PI = Math.PI * 2
const CX = 75
const CY = 75
const R1 = 50
const R2 = 75

function SVGPie({center, rings, colors, theme, style}){
  // console.log(colors, rings)
  const maxs = rings.reduce( (x,acc) => x + acc, 0)
  if (maxs == 0){
    return null
  }
  let ringsp

  if (rings.length <=1){
    ringsp = [
      ["75 25", "74.99688067929823 25.000000097301616", "74.99532101894735 1.459524270330803e-7", "75 0", 1]
      // ["75 125", "75 25", "75 0", "75 150", 1]
    ]
  } else {
    const sc = _2PI / maxs
    let prev = [`${CX} ${CY - R1}`, `${CX} ${CY - R2}`]
    let acc = -Math.PI/2

    ringsp = rings.map( ring =>{
      const a = ring * sc
      // console.log(acc, a, ring / maxs)
      acc += a
      const next = [
        `${CX + Math.cos(acc) * R1} ${CY + Math.sin(acc) * R1}`,
        `${CX + Math.cos(acc) * R2} ${CY + Math.sin(acc) * R2}`,
      ]
      const ret = [
        prev[0], next[0], next[1], prev[1], ((a>3.14) ? 1 : 0),
      ]
      prev = next
      return ret
    })
  }
  const bgcolor = theme == "dark" ? "#2b444a" : "white"
  const fgcolor = theme == "dark" ? "#ddd" : "black"

  // console.log(ringsp)
  return (
    <svg viewBox="0 0 150 150" style={{style}}>
      <text x={CX} y={CY + 11} textAnchor="middle" style={{fontSize: 22, fontWeight: "bold", fill: fgcolor}}>{center}</text>
      {ringsp.map( (r,i) => (
        <path
          key={r}
          d={`M ${r[0]} A ${R1} ${R1} 0 ${r[4]} 1 ${r[1]} L ${r[2]} A ${R2} ${R2} 0 ${r[4]} 0 ${r[3]} Z`}
          style={{fill: colors[i]}}
          />
      ))}
      {ringsp.map( (r,i) => (
        <path
          key={r}
          d={`M ${r[0]} L ${r[3]} Z`}
          style={{stroke: bgcolor, strokeWidth: "2"}}
          />
      ))}
    </svg>
  )
}

class Pie3 extends React.Component{
  componentDidMount(){
    this.props.setTitle(this.props.config.title)
  }
  componentWillReceiveProps(nextprops){
    if (map_get(nextprops, ["config","title"]) != map_get(this.props, ["config","title"]))
      this.props.setTitle(map_get(nextprops, ["config","title"]))
  }
  shouldComponentUpdate(nextprops){
    return !object_is_equal(nextprops.config, this.props.config)
  }
  render(){
    const props = this.props
    const config = props.config
    let rows = map_get(config,["data", "rows"])

    if (!rows)
      return (
        <Loading.Widget/>
      )

    rows = rows.sort( (a,b) => b[1] - a[1])

    if (rows.length>4){
      // max 4, if more, 3 + others
      // console.log("rows", rows)
      const rest = rows.slice(3,1000).reduce((acc, row) => to_number(row[1]) + acc, 0)
      // console.log("rest", rest)
      rows=[
        rows[0],
        rows[1],
        rows[2],
        [i18n("Other"), rest.toFixed(2), ""],
      ]

    }


    let rings
    try{
      rings = rows.map( r => to_number(r[1]))
    } catch (e) {
      console.log(e)
      return (
        <Error>
          {i18n("Invalid data for pie chard. Second column must be numbers")}
        </Error>
      )
    }

    const layout = props.layout
    let main_style
    if (layout.w == layout.h) {
      main_style = {
        display: "grid",
        gridTemplateAreas: '"summary pie" "data data"',
        gridTemplateColumns: "1fr 1fr",
        gridTemplateRows: "1fr 1fr",
        maxHeight: layout.height,
        maxWidth: layout.width,
      }
    } else if (layout.w > layout.h) {
      main_style = {
        display: "grid",
        gridTemplateAreas: '"pie summary" "pie data"',
        gridGap: "30px",
        gridTemplateColumns: "1fr 1fr",
        gridTemplateRows: "1fr 3fr",
        maxHeight: layout.height,
        maxWidth: layout.width,
      }
    } else {
      main_style = {
        display: "grid",
        gridTemplateAreas: '"summary" "pie" "data"',
        gridTemplateRows: "1fr 2fr 2fr",
        maxHeight: layout.height,
        maxWidth: layout.width,
      }
    }
    const bottom_size = rows.length * 42

    let maxhw = Math.min(layout.width, layout.height) - 30
    if (layout.h > layout.w){
      maxhw = Math.min(maxhw, layout.height - bottom_size - 80)
    }

    let svg_area_style = {
      gridArea: "pie",
      maxWidth: maxhw,
      maxHeight: maxhw,
      width: "100%",
      height: "100%",
      alignSelf: "center",
      justifySelf: "center",
      textAlign: "center",
    }
    let svg_style = {
      maxHeight: maxhw
    }

    const fill = colorize_list_hex(rows.map( r => r[0]), props.config.palette)
    console.log("maxhw", maxhw)

    return (
      <div className="ui with padding" style={main_style}>
        <div className="ui biggier bold centered text" style={{gridArea: "summary", alignSelf: "center"}}>
          {get_data(config.summary, [0,0])}
        </div>
        <div className="ui centered" style={svg_area_style}>
          <SVGPie
            style={svg_style}
            center={get_data(config.summary, [0,1])}
            rings={rings}
            colors={fill}
            theme={props.theme}
            />
        </div>
        <div style={{gridArea: "data", alignSelf: "center"}}>
          <table style={{width: "100%"}}>
            <tbody>
              {rows.map( (r,i) => (
                <tr key={r[0]} style={{height: "3em"}}>
                  <td className="ui ellipsis">
                    <span className="ui square" style={{marginRight: 5, background: fill[i]}}/>
                    {r[0]}
                  </td>
                  <td className="ui big bold text right aligned">{r[1]}</td>
                  <td className={`ui right aligned small text ${r[2] < 0 ? "red" : "teal"}`}>
                    {r[2]}
                  </td>
                </tr>
              ) ) }
            </tbody>
          </table>
        </div>
      </div>
    )
  }
}

Serverboards.add_widget("serverboards.core.widgets/pie3", Pie3, {react: true})
