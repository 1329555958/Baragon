import React, { Component, PropTypes } from 'react';
import { connect } from 'react-redux';
import classNames from 'classnames';
import { Link } from 'react-router';
import rootComponent from '../../rootComponent';
import { refresh } from '../../actions/ui/serviceDetail';
import Utils from '../../utils';

class ServiceDetail extends Component {
  render() {
    // TODO - render out info nicely
    //  - JSON button (or other display?) for request history items
    // - reload / delete service / json button (use existing modals)
    // - Remove upstream (requires new modal + building request json)
    //   - submit request modal should either show request json or link to page for it
    return <h1>Service Detail</h1>
  }

  static propTypes = {
    params: PropTypes.object.isRequired,
    service: React.PropTypes.object,
    requestHistory: React.PropTypes.array
  };
}

export default connect((state, ownProps) => ({
  service: Utils.maybe(state, ['api', 'service', ownProps.params.serviceId, 'data']),
  requestHistory: Utils.maybe(state, ['api', 'requestHistory', ownProps.params.serviceId, 'data'])
}))(rootComponent(ServiceDetail, (props) => refresh(props.params.serviceId)));